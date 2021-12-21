xquery version "3.1" encoding "UTF-8";
(:~
 : test implementation of the https://github.com/distributed-text-services
 : SERVER
 : @author Pietro Liuzzo 
 :)

module namespace localdts = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/localdts";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace s = "http://www.w3.org/2005/xpath-functions";
declare namespace t="http://www.tei-c.org/ns/1.0";
declare option output:method "json";

import module namespace dtslib = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/dtslib" at "xmldb:exist:///db/apps/BetMasWeb/modules/dtslib.xqm";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace console="http://exist-db.org/xquery/console";

declare function localdts:Collection($id as xs:string*, $page as xs:integer*, $nav as xs:string*) as map(*) {
    if (matches($id, '(https://betamasaheft.eu/)?(textualunits/|narrativeunits/|transcriptions/|studies/)?([a-zA-Z\d]+)?(:)?(((\d+)(\w)?(\w)?((@)([\p{L}]+)(\[(\d+|last)\])?)?)?(\-)?((\d+)(\w)?(\w)?((@)([\p{L}]+)(\[(\d+|last)\])?)?)?)')) then
            let $parsedURN := dtslib:parseDTS($id)
            return
                if (matches($parsedURN//s:group[@nr = 2], '(textualunits|narrativeunits|transcriptions|studies)'))
                then
                    (localdts:Coll($id, $page, $nav, ''))
                else
                    if (matches($parsedURN//s:group[@nr = 3], '[a-zA-Z\d]+'))
                    then
                        (
                        let $specificID := $parsedURN//s:group[@nr = 3]/text()
                        let $edition := $parsedURN//s:group[@nr = 4]
                        return
                            localdts:CollMember($id, $edition, $specificID, $page, $nav, ''))
                    else
                        localdts:Coll($id, $page, $nav, '')
        else
            ()
};

declare function localdts:Coll($id, $page, $nav, $version) {
let $availableCollectionIDs := ('https://betamasaheft.eu', 'https://betamasaheft.eu/textualunits', 'https://betamasaheft.eu/narrativeunits', 'https://betamasaheft.eu/transcriptions','https://betamasaheft.eu/studies')
let $ms := $dtslib:collection-rootMS//t:div[@type eq 'edition'][descendant::t:ab[text()]]
let $w := $dtslib:collection-rootW//t:div[@type eq 'edition'][descendant::t:ab[text()]]
let $n := $dtslib:collection-rootN
let $s := $dtslib:collection-rootS
  let $countMS := count($ms)
  let $countW := count($w)
  let $countN := count($n)
  let $countS := count($s)
    return
       (
 if($id = $availableCollectionIDs) then (
 switch($id) 
 case 'https://betamasaheft.eu/textualunits' return
dtslib:mainColl($id, $countW, $w, $page, $nav)
 case 'https://betamasaheft.eu/narrativeunits' return
dtslib:mainColl($id, $countN, $n, $page, $nav)
case 'https://betamasaheft.eu/transcriptions' return
dtslib:mainColl($id, $countMS, $ms, $page, $nav)
case 'https://betamasaheft.eu/studies' return
dtslib:mainColl($id, $countS, $ms, $page, $nav)
default return
map {
    "@context": $dtslib:context,
    "@id": $id,
    "@type": "Collection",
    "totalItems": 3,
    "title": "Beta maṣāḥǝft",
    "description" : "The project Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea (Schriftkultur des christlichen Äthiopiens: eine multimediale Forschungsumgebung) is a long-term project funded within the framework of the Academies' Programme (coordinated by the Union of the German Academies of Sciences and Humanities) under survey of the Akademie der Wissenschaften in Hamburg. The funding will be provided for 25 years, from 2016–2040. The project is hosted by the Hiob Ludolf Centre for Ethiopian Studies at the University of Hamburg. It aims at creating a virtual research environment that shall manage complex data related to predominantly Christian manuscript tradition of the Ethiopian and Eritrean Highlands.",
    "dts:dublincore": $dtslib:publisher,
    "member": [
        map {
             "@id" : "https://betamasaheft.eu/textualunits",
             "title" : "Beta maṣāḥǝft Textual Units",
             "description": "Collection of textual units of the Ethiopic tradition",
             "@type" : "Collection",
             "totalItems" : $countW
        },
         map {
             "@id" : "https://betamasaheft.eu/narrativeunits",
             "title" : "Beta maṣāḥǝft Narrative Units",
             "description": "Collection of narrative units of the Ethiopic tradition",
             "@type" : "Collection",
             "totalItems" : $countN
        },
        map{
             "@id" : "https://betamasaheft.eu/transcriptions",
             "title" : "Beta maṣāḥǝft Manuscripts",
             "description": "Collection of Ethiopic Manuscript transcriptions",
             "@type" : "Collection",
             "totalItems" : $countMS
        },
        map{
             "@id" : "https://betamasaheft.eu/studies",
             "title" : "Beta maṣāḥǝft Studies",
             "description": "Collection of Studies on Ethiopic Manuscript tradition",
             "@type" : "Collection",
             "totalItems" : $countS
        }
    ]
})
 else (
map {
  "@context": "http://www.w3.org/ns/hydra/context.jsonld",
  "@type": "Status",
  "statusCode": 404,
  "title": "Not Found",
  "description": "Unknown Collection"
})
)
};

declare function localdts:CollMember($id, $edition, $bmID, $page, $nav, $version){
let $doc := $dtslib:collection-root//id($bmID) 
let $eds := if($edition/node()) then
                                dtslib:pickDivText($doc, $edition)
                    else ($doc//t:div[@type eq 'edition'], $doc//t:div[@type eq 'translation'])
return
if(count($doc) eq 1) then (
let $memberInfo := dtslib:member($bmID,$edition,$eds, $version, 'nosparql')
let $addcontext := map:put($memberInfo, "@context", $dtslib:context)
let $addnav := if($nav = 'parent') then 
let $parent :=if($doc/@type eq 'mss') then 
        map{
             "@id" : "https://betamasaheft.eu/transcriptions",
             "title" : "Beta maṣāḥǝft Manuscripts",
             "description": "Collection of Ethiopic Manuscript transcriptions",
             "@type" : "Collection",
             "totalItems" : count(collection($config:data-rootMS)//t:div[@type eq 'edition'][descendant::t:ab[text()]])
        }
       else if($doc/@type eq 'nar') then 
        map{
             "@id" : "https://betamasaheft.eu/narrativeunits",
             "title" : "Beta maṣāḥǝft Manuscripts",
             "description": "Collection of narrative units of the Ethiopic tradition",
             "@type" : "Collection",
             "totalItems" : count(collection($config:data-rootN)//t:div[@type eq 'edition'][descendant::t:ab[text()]])
        }
         else if($doc/@type eq 'studies') then 
        map{
             "@id" : "https://betamasaheft.eu/narrativeunits",
             "title" : "Beta maṣāḥǝft Manuscripts",
             "description": "Collection of Studies on the Ethiopic manuscript tradition",
             "@type" : "Collection",
             "totalItems" : count(collection($config:data-rootS)//t:div[@type eq 'edition'][descendant::t:ab[text()]])
        }
        else map {
             "@id" : "https://betamasaheft.eu/textualunits",
             "title" : "Beta maṣāḥǝft Textual Units",
             "description": "Collection of literary textual units of the Ethiopic tradition",
             "@type" : "Collection",
             "totalItems" : count($dtslib:collection-rootW//t:div[@type eq 'edition'][descendant::t:ab[text()]])
        }
return
map:put($addcontext, "member", $parent) 
else $addcontext
return 
$addnav
) 
else
(
map {
  "@context": "http://www.w3.org/ns/hydra/context.jsonld",
  "@type": "Status",
  "statusCode": 400,
  "title": "Bad Request",
  "description": "There is none or too many "||$bmID
}
)

};


declare function localdts:Document($id as xs:string*, $ref as xs:string*, $start, $end) {
dtslib:docs($id, $ref, $start, $end, 'application/tei+xml')
};


declare function localdts:Navigation($id as xs:string*, $ref as xs:string*, 
$level as xs:string*, $start as xs:string*, $end as xs:string*, 
$groupBy as xs:string*, $page as xs:string*, $max as xs:string*, 
$version as xs:string*) as map(*) {

let $parsedURN := dtslib:parseDTS($id)
let $BMid := $parsedURN//s:group[@nr=3]/text()

let $mydoc := collection($config:data-root)/id($BMid)
let $edition := $parsedURN//s:group[@nr=4]
let $text := if($edition/node()) then dtslib:pickDivText($mydoc, $edition)  else $mydoc//t:div[@type eq 'edition']
                (: there may be more edition and translations how are these fetched?  
                LIT1709Kebran, LIT1758Lefafa multiple editions 
                LIT2170Peripl multiple pb and divs + images
                
                there needs to be evidence of multiple editions and a possibility to 
                switch based on @xml:id
                with fallback on div[@type eq 'edition']
                multiple values for navigation api provided in Collection 
                
                LIT4915PhysA_ED_ed1.1.1.1
                LIT4915PhysA_ED_ed2.1.1
                LIT2170Peripl_ED_
                LIT2170Peripl_TR_
                :)
             
let $textType := $mydoc//t:objectDesc/@form
let $manifest := $mydoc//t:idno/@facs
let $allwits := dtslib:wits($mydoc, $BMid) 
let $witnesses := for $witness in config:distinct-values($allwits)
(:filters out the witnesses which do not have images available:)
                            return if(starts-with($witness, 'http')) then $witness else let $mss := $dtslib:collection-rootMS/id($witness) return if ($mss//t:idno/@facs) then $witness else ()
let $cdepth := dtslib:citeDepth($text)
let $passage := 
if ($mydoc/@type eq 'mss' and not($textType='Inscription')) then (
   (:manuscripts:)

(:  THERE IS A REF:)   
    if($ref != '') then 
             let $l := if ($level='') then 1 else $level
               
           return
          dtslib:pasRef($l, $text, $ref, 'unit', 'mss', $manifest, $BMid)
(:$ref can be a NAR, but how does one know that this is a possibility within this text?:)

(:start and end:)
     else if($start != '') then
             dtslib:startend($level, $text, $start, $end, 'part', 'mss', $manifest, $BMid)
   (: no ref specified, list all main divs, assuming by the guidelines they are folios:)
         else if($ref='' and $level = '' and $start ='' and $end = ''and $groupBy = '' and $max = '') 
                then dtslib:pasS($text/t:div[@n], 'folio', 'mss', $manifest, $BMid)
  (: if the level is not empty, than it has been specified to be either the second or third level, pages and columns                  :)
         else if (($level != '') and ($cdepth gt 3))  then
  (:  the citation depth is higer than 3:)
(:  let $t := console:log($level) return:)
                  dtslib:pasLev($level, $text, 'unit', 'mss', $manifest, $BMid )
        else if(($level != '') and ($cdepth = 3)) then 
                  (if ($level = '2') 
  (: the pages of folios have been requested:)
                    then dtslib:pasS($text//t:pb[@n], 'page', 'mss', $manifest, $BMid)
                    else if ($level = '3')
  (: the columns of a pages have been requested:)
                     then dtslib:pasS($text//(t:cb[@n]), 'column', 'mss', $manifest, $BMid)
                     else if ($level = '4')
  (: the columns of a pages have been requested:)
                     then dtslib:pasS($text//(t:lb[@n]), 'line', 'mss', $manifest, $BMid)
  (:  in theory there is no such case which will not be matched by cdepth gt 3...   :)
                     else()  )         
(:    no other option taken into consideration:)
    else ()
                        ) else 
(:works and inscriptions. 
                        textual units have different structures 
                        some are encoded with a basic nested divs structure, some instaed, especially bible texts use l, while inscriptions have lb :)
                                if($ref='' and $level = '' and $start ='' and $end = ''and $groupBy = '' and $max = '') 
(:   if no  parameter is specified, go through the child elements of div type edition, whatever they are:)
                                then 
                                dtslib:pasS($text/(t:ab|.)/t:*, 'unit', 'work', $witnesses, $BMid)
(:   if a ref is specified show that navigation point:)
else if($ref != '' and $start = '')  
(:e.g. LIT1546Genesi&ref=2.3 :)
        then dtslib:pasRef(1, $text, $ref, 'unit', 'work', $witnesses, $BMid)
(:   if a level is specified that use that information, and check for ref
e.g. LIT1546Genesi&level=2
:) 
 else if($level != '' and $start = '') 
                                then 
(:  e.g. LIT1546Genesi&level=2&ref=4:)
                                if($ref != '') then dtslib:pasRef($level, $text, $ref, 'unit', 'work', $witnesses, $BMid)
(:  e.g. LIT1546Genesi&level=2 (max level is value of citeDepth!):)                               
                               else dtslib:pasLev($level, $text, 'unit', 'work', $witnesses, $BMid )
 else if($start != '' and $end != '') 
(: needs to make a sequence of possible 
refs at the given level and limit it by the positions in $start and $end
LIT1546Genesi&start=3&end=4 :)
               then 
              dtslib:startend($level, $text, $start, $end, 'texpart', 'work', $witnesses, $BMid)
else ()
                             
(:                             the following step should take the list of results and format it using the chunksize and max parameters:)
let $CS := number($groupBy)
let $M := number($max)
let $ctype := dtslib:ctype($mydoc,$text, $level, $cdepth)
let $chunkedpassage := if(string($groupBy) !='') 
                                                then       
                                               (
                                                        for $p in $passage/text() 
                                                        let $l1 := substring-before($p,'.')
                                                        let $l2 := number(substring-after($p, '.')) -1
                                                        let $L := $l2 - ($l2 mod $CS)
                                                        group by $g:= $L 
                                                        order by $g
                                                        let $rangeStart := if($g= 0) then 1 else $g +1
                                                        let $ceiling:= $g+$CS
                                                        let $sequenceN := for $p in $passage return  number(substring-after($p, '.'))
                                                        let $end := max($sequenceN)
                                                        let $rangeEnd := if($ceiling gt $end) then $end else $ceiling
                                                        let $chunck  := map {'dts:start' :  $passage[$rangeStart]/text()[1], 'dts:end' : $passage[$rangeEnd]/text()[1]}
                                                       return 
                                                                    $chunck)
                                                else for $p in $passage 
                                                            let $refonly := map {"dts:ref" : $p/text()[1]}
                                                         let $refandtype := if((count($p/*:type) eq 1) and ($p/*:type/text() !=$ctype)) then map:put($refonly, 'dts:citeType', $p/*:type/text()) else $refonly
                                                         let $refTypeTitle := if(count($p/*:title) eq 1 or count($p/*:iiifRange) ge 1) 
                                                                                        then 
                                                                                                    let $dublincore := map{}
                                                                                                    let $parttitle := if($p/*:title) then map:put($dublincore, 'dc:title', $p/*:title/text()) else $dublincore
                                                                                                    let $iiifreference := for $i in $p/*:iiifRange 
                                                                                                                                    return map {"@id": $i/text(),  
                                                                                                                                                       "@type": (if(contains($i/text(), 'canvas'))  
                                                                                                                                                                                                 then "sc:Canvas" 
                                                                                                                                                                                                 else  "sc:Range")}                                                                                     
                                                                                                    let $parttitlewithmanifest := if(count($iiifreference) ge 1) then map:put($parttitle, 'dc:source', $iiifreference) else $parttitle
                                                                                                    return map:put($refandtype, 'dts:dublincore', $parttitlewithmanifest) 
                                                                                         else   $refandtype
                                                         return 
                                                         $refTypeTitle
                                                 

(: regardless of passages sequence type (ranges as maps or items as strings) the following steps limits the number of results                                                :)
let $maximized :=if(string($max) !='') then for $p in subsequence($chunkedpassage, 1, $M) return $p else $chunkedpassage
let $array := array{$maximized}
 let $l := if($level = '') then 1 else number($level)
let $versions := if($version='yes') then  dtslib:fileingitCommits($id, $BMid, 'navigation') else ('version set to '||$version||', no version links retrieved from GitHub.')

return
     map {
    "@context": map {
        "@vocab": "https://www.w3.org/ns/hydra/core#",
        "dc": "http://purl.org/dc/terms/",
        "dts": "https://w3id.org/dts/api#"
    },
    "@base": "/api/dts/navigation",
    "@id": ('/api/dts/navigation?id='|| $id),
    "dts:citeDepth" : $cdepth,
    "dts:level" : $l,
    "dts:citeType": $ctype,
    "dc:hasVersion" : $versions,
    "dts:passage" : ('/api/dts/document?id=' || $id),
    "member": $array
}
         
};



declare function localdts:Annotations($coll as xs:string*, $BMid as xs:string*, 
$begin as xs:string*, $page as xs:string*, $version as xs:string*){
let $indexes := ('persons', 'places','keywords', 'loci', 'works')
let $file := dtslib:switchContext($coll)/id($BMid)
let $title := $BMid
let $availableIndexesForItem :=   
                                    for $index in $indexes 
                                    let $count := dtslib:ItemAnnotationsEntries($file, $index)
                                    return if($count=0) then () 
                                    else dtslib:ItemAnnotationCollections($coll,$BMid, $title, $index, $count, 3)
let $c := count($availableIndexesForItem)
let $topinfo := map {
    "@type" : 'AnnotationCollection',
    "title": "Annotations of "||$title||" in "||$coll,
    "@id": $config:appUrl || '/api/dts/annotations/' ||$coll ||'/items/' || $BMid,
    "totalItems": $c,
    "dts:totalParents": 3,
    "dts:totalChildren": $c
    }

let $contents:=
map {
    "@context": $dtslib:context,
    "member": $availableIndexesForItem,
    "dts:dublincore": $dtslib:publisher
} 
return

map:merge(($topinfo,$contents))
};

