xquery version "3.1" encoding "UTF-8";
(:~
 : test implementation of the https://github.com/distributed-text-services
 : 
 : @author Pietro Liuzzo 
 : to do 
 : if I want to retrive 1ra@ወወልድ[1]-3vb, should the  @ወወልድ[1] piece also be in the passage/start/end parameter 
: 
: add Hydra navigation instead of the header links
:
: "view": {
:        "@id": "/api/dts/document/?id=lettres_de_poilus&passage=19",
:        "@type": "PartialDocumentView",
:        "first": "/api/dts/document/?id=lettres_de_poilus&passage=1",
:        "previous": "/api/dts/document/?id=lettres_de_poilus&passage=18",
:       "next": "/api/dts/document/?id=lettres_de_poilus&passage=20",
:       "last": "/api/dts/docuemtn/?id=lettres_de_poilus&passage=500"
:   }
:
: add possibility of having a collection grouping by institution or catalogue for the manuscripts
: 
: urn:dts:betmasMS:INS0012bla:BLorient12314
:
: urn:dts:betmasMS:Zotemberg1234:BLorient12314
 :)

module namespace persdts="https://www.betamasaheft.uni-hamburg.de/BetMas/persdts";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace t="http://www.tei-c.org/ns/1.0";
declare namespace exist = "http://exist.sourceforge.net/NS/exist";
declare namespace s = "http://www.w3.org/2005/xpath-functions";
declare namespace http = "http://expath.org/ns/http-client";
declare namespace json = "http://www.json.org";
declare namespace cx ="http://interedition.eu/collatex/ns/1.0";
declare namespace sr="http://www.w3.org/2005/sparql-results#";
declare namespace test="http://exist-db.org/xquery/xqsuite";

import module namespace functx="http://www.functx.com";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMas/modules/log.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace fusekisparql = 'https://www.betamasaheft.uni-hamburg.de/BetMas/sparqlfuseki' at "xmldb:exist:///db/apps/BetMas/fuseki/fuseki.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMas/string" at "xmldb:exist:///db/apps/BetMas/modules/tei2string.xqm";
import module namespace editors = "https://www.betamasaheft.uni-hamburg.de/BetMas/editors" at "xmldb:exist:///db/apps/BetMas/modules/editors.xqm";
import module namespace dts="https://www.betamasaheft.uni-hamburg.de/BetMas/dts" at "xmldb:exist:///db/apps/BetMas/modules/dts.xqm";


  declare variable $persdts:collection-rootMS  := collection($config:data-rootMS);   
  declare variable $persdts:collection-root  := $titles:collection-root; 
  
  
declare option output:method "json";
declare option output:indent "yes";

  declare function persdts:capitalize-first
  ( $arg as xs:string? )  as xs:string? {

   concat(upper-case(substring($arg,1,1)),
             substring($arg,2))
 } ;

(:~ Main access point to DTS style API returning passages from text :)
declare
%rest:GET
%rest:path("/BetMas/permanent/{$sha}/api/dts")
%output:method("json")
function persdts:dtsmain($sha as xs:string+) {
let $perma :=  ("/permanent/"||$sha||"/api/dts/")
let $col :=$perma || 'collections'
let $doc := $perma || 'document'
let $nav :=$perma || 'navigation'
return
  ( $config:response200JsonLD,
  map {
  "@context": "/dts/api/contexts/EntryPoint.jsonld",
  "@id": "/api/dts/",
  "@type": "EntryPoint",
  "documents": $doc,
  "navigation" : $nav
})
         
};

(:~ dts/collection https://github.com/distributed-text-services/specifications/blob/master/Collection-Endpoint.md :)
declare
%rest:GET
%rest:path("/BetMas/permanent/{$sha}/api/dts/collections")
%rest:query-param("id", "{$id}",  "")
%rest:query-param("page", "{$page}", 1)
%rest:query-param("nav", "{$nav}", "children")
%output:method("json")
function persdts:Collection($id as xs:string*,$page as xs:integer*,$nav as xs:string*,$sha as xs:string*) {
if($id = '') then (
 <rest:response>
  <http:response status="302">
    <http:header name="location" value="/permanent/{$sha}/api/dts/collections?id=https://betamasaheft.eu"/>
  </http:response>
</rest:response>
) else
if(matches($id, '(https://betamasaheft.eu/)?(textualunits/|narrativeunits/|transcriptions/)?([a-zA-Z\d]+)?(:)?(((\d+)(\w)?(\w)?((@)([\p{L}]+)(\[(\d+|last)\])?)?)?(\-)?((\d+)(\w)?(\w)?((@)([\p{L}]+)(\[(\d+|last)\])?)?)?)')) 
then (
let $parsedURN := dts:parseDTS($id)
return
if (matches($parsedURN//s:group[@nr eq 3], '[a-zA-Z\d]+'))
then (
                let $specificID := $parsedURN//s:group[@nr eq 3]/text() 
                return persdts:CollMember($id, $specificID, $page, $nav, $sha))
else
persdts:Coll($id, $page, $nav, $sha)
)
else 
(
$config:response400 ,
let $error := $id|| "is not a valid URN pattern"
return
map {
  "@context": "http://www.w3.org/ns/hydra/context.jsonld",
  "@type": "Status",
  "statusCode": 400,
  "title": "Not Found",
  "description": " Resource requested is not found ", "error": $error}
)
};


(:~ dts/document https://github.com/distributed-text-services/specifications/blob/master/Document-Endpoint.md:)
declare
%rest:GET
%rest:path("/BetMas/permanent/{$sha}/api/dts/document")
%rest:query-param("id", "{$id}",  "")
%rest:query-param("ref", "{$ref}", "")
%rest:query-param("start", "{$start}", "")
%rest:query-param("end", "{$end}", "")
%output:method('xml')
%output:omit-xml-declaration("no")
function persdts:anyDocument($id as xs:string*, $ref as xs:string*, $sha as xs:string*, $start , $end) {
if ($id = '') then (
 <rest:response>
  <http:response status="302">
    <http:header name="location" value="/permanent/{$sha}/api/dts/collections?id=https://betamasaheft.eu"/>
  </http:response>
</rest:response>
) else
 let $parsedURN := dts:parseDTS($id)
 return
if($ref != '' and (($start != '') or ($end != ''))) then ($config:response400XML, <error statusCode="400" xmlns="https://w3id.org/dts/api#">
  <title>Bad Request</title>
  <description>You should use start and end, or passage only</description>
</error>) 
else if (($start = '' and $end != '') or ($start != '' and $end = '') ) then ($config:response400XML, 
<error statusCode="400" xmlns="https://w3id.org/dts/api#">
  <title>Bad Request</title>
  <description>You cannot use start and end disjunted</description>
</error>) 
else 

let $links := if ($ref = '') then () 
else if ($start != '') then <http:header
                    name="Link"
                    value="&lt;/permanent/{$sha}/api/dts/document?id={$id}&amp;ref={number($start) - 1}&gt; ; rel='prev', &lt;/api/dts/document/?id={$id}&amp;ref={number($end) + 1}&gt; ; rel='next'"/>

else <http:header
                    name="Link"
                    value="&lt;/permanent/{$sha}/api/dts/document?id={$id}&amp;ref={number($ref) - 1}&gt; ; rel='prev', &lt;/api/dts/document/?id={$id}&amp;ref={number($ref) + 1}&gt; ; rel='next'"/>
                    
 return
(:we need a restxq redirect in case the id contains already the passage. it should redirect the urn with passage to one which splits it and redirect it to a parametrized query:)
 if(count($parsedURN//s:group[@nr eq 5]//text()) ge 1) then 
 let $location := if($parsedURN//s:group[@nr eq 15]/text() = '-') 
                    then ('permanent/'||$sha||'/api/dts/document?id='||$parsedURN//s:group[@nr eq 1]//text()||$parsedURN//s:group[@nr eq 2]//text()||$parsedURN//s:group[@nr eq 3]//text()|| '&amp;start=' ||$parsedURN//s:group[@nr eq 6]//text()|| '&amp;end=' ||$parsedURN//s:group[@nr eq 16]//text()) 
                    else ('permanent/'||$sha||'/api/dts/document?id='||$parsedURN//s:group[@nr eq 1]//text()||$parsedURN//s:group[@nr eq 2]//text()||$parsedURN//s:group[@nr eq 3]//text()|| '&amp;ref=' ||$parsedURN//s:group[@nr eq 5]//text())
 return
 <rest:response>
  <http:response status="302">
    <http:header name="location" value="{ $location }"/>
  </http:response>
</rest:response>
 else
 let $thisid := $parsedURN//s:group[@nr eq 3]/text()
 let $edition := $parsedURN//s:group[@nr eq 4]
 let $currentfile := $persdts:collection-root/id($id)[self::t:TEI]
 let $collection := if($currentfile/@type eq 'mss') then 'Manuscripts'  else  if($currentfile/@type eq 'narr') then 'Narrative' else 'Works'
let $permapath := replace(persdts:capitalize-first(substring-after(base-uri($cfile), '/db/apps/BetMasData/')), $collection, '')
let $file:= doc('https://raw.githubusercontent.com/BetaMasaheft/' || $collection || '/'||$sha||'/'|| $permapath)//t:TEI
let $text := if($edition/node()) then dts:pickDivText($file, $edition)  else $file//t:div[@type eq 'edition']
let $doc := dts:fragment($file, $edition, $ref, $start, $end, $text)
                       
 return
  ( <rest:response>
  <http:response
                status="200">
                <http:header
                    name="Content-Type"
                    value="application/tei+xml; charset=utf-8"/>
                <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"/>
                   {$links}
            </http:response>
        </rest:response>,
  $doc
  )     
};

(:~ dts/navigation https://github.com/distributed-text-services/specifications/blob/master/Navigation-Endpoint.md:)
declare
%rest:GET
%rest:path("/BetMas/permanent/{$sha}/api/dts/navigation")
%rest:query-param("id", "{$id}",  "")
%rest:query-param("ref", "{$ref}", "")
%rest:query-param("level", "{$level}", "")
%rest:query-param("start", "{$start}", "")
%rest:query-param("end", "{$end}", "")
%rest:query-param("page", "{$page}", "")
%rest:query-param("groupBy", "{$groupBy}", "")
%rest:query-param("max", "{$max}", "")
%output:method("json")
function persdts:Cit($sha as xs:string*, $id as xs:string*, $ref as xs:string*, $level as xs:string*, $start as xs:string*, $end as xs:string*, $groupBy as xs:string*, $page as xs:string*, $max as xs:string*) {
if($id = '') then (<rest:response>
  <http:response status="302">
    <http:header name="location" value="/permanent/{$sha}/api/dts/collections?id=https://betamasaheft.eu"/>
  </http:response>
</rest:response>) else
let $parsedURN := dts:parseDTS($id)
let $BMid := $parsedURN//s:group[@nr eq 3]
let $edition := $parsedURN//s:group[@nr eq 4]
let $file:= persdts:fileingit($id, $BMid, $sha)
let $text := if($edition/node()) then dts:pickDivText($mydoc, $edition)  else $mydoc//t:div[@type eq 'edition']
let $textType := $file//t:objectDesc/@form
let $allwits := dts:wits($file, $BMid) 
let $witnesses := for $witness in config:distinct-values($allwits)
(:filters out the witnesses which do not have images available:)
                            return if(starts-with($witness, 'http')) then $witness else let $mss := $persdts:collection-rootMS/id($witness) return if ($mss//t:idno/@facs) then $witness else ()
let $cdepth := dts:citeDepth($text)

let $passage :=  
if ($file/@type eq 'mss' and not($textType='Inscription')) then (
   (:manuscripts:)

(:  THERE IS A REF:)   
    if($ref != '') then 
             let $l := if ($level='') then 1 else $level
           return
          dts:pasRef($l, $text, $ref, 'unit', 'mss', $manifest, $BMid)
(:$ref can be a NAR, but how does one know that this is a possibility within this text?:)

(:start and end:)
     else if($start != '') then
             dts:startend($level, $text, $start, $end, 'part', 'mss', $manifest, $BMid)
   (: no ref specified, list all main divs, assuming by the guidelines they are folios:)
         else if($ref='' and $level = '' and $start ='' and $end = ''and $groupBy = '' and $max = '') 
                then dts:pasS($text/t:div[@n], 'folio', 'mss', $manifest, $BMid)
  (: if the level is not empty, than it has been specified to be either the second or third level, pages and columns                  :)
         else if (($level != '') and ($cdepth gt 3))  then
  (:  the citation depth is higer than 3:)
(:  let $t := console:log($level) return:)
                  dts:pasLev($level, $text, 'unit', 'mss', $manifest, $BMid )
        else if(($level != '') and ($cdepth = 3)) then 
                  (if ($level = '2') 
  (: the pages of folios have been requested:)
                    then dts:pasS($text//t:pb[@n], 'page', 'mss', $manifest, $BMid)
                    else if ($level = '3')
  (: the columns of a pages have been requested:)
                     then dts:pasS($text//(t:cb[@n]), 'column', 'mss', $manifest, $BMid)
                     else if ($level = '4')
  (: the columns of a pages have been requested:)
                     then dts:pasS($text//(t:lb[@n]), 'line', 'mss', $manifest, $BMid)
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
                                then  dts:pasS($text/(t:ab|.)/t:*, 'unit', 'work', $witnesses, $BMid)
(:   if a ref is specified show that navigation point:)
else if($ref != '' and $start = '')  
(:e.g. LIT1546Genesi&ref=2.3 :)
        then dts:pasRef(1, $text, $ref, 'unit', 'work', $witnesses, $BMid)
(:   if a level is specified that use that information, and check for ref
e.g. LIT1546Genesi&level=2
:) 
 else if($level != '' and $start = '') 
                                then 
(:  e.g. LIT1546Genesi&level=2&ref=4:)
                                if($ref != '') then dts:pasRef($level, $text, $ref, 'unit', 'work', $witnesses, $BMid)
(:  e.g. LIT1546Genesi&level=2 (max level is value of citeDepth!):)                               
                               else dts:pasLev($level, $text, 'unit', 'work', $witnesses, $BMid )
 else if($start != '' and $end != '') 
(: needs to make a sequence of possible 
refs at the given level and limit it by the positions in $start and $end
LIT1546Genesi&start=3&end=4 :)
               then 
              dts:startend($level, $text, $start, $end, 'texpart', 'work', $witnesses, $BMid)
else ()
                             
(:                             the following step should take the list of results and format it using the chunksize and max parameters:)
let $CS := number($groupBy)
let $M := number($max)
let $ctype := dts:ctype($mydoc,$text, $level, $cdepth)
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
                                                        let $chunck  := map {'start' :  $passage[$rangeStart], 'end' : $passage[$rangeEnd]}
                                                       return 
                                                                    $chunck)
                                                else for $p in $passage 
                                                            let $refonly := map {"ref" : $p/text()}
                                                         let $refandtype := if((count($p/type) eq 1) and ($p/type/text() !=$ctype)) then map:put($refonly, 'dts:citeType', $p/type/text()) else $refonly
                                                         let $refTypeTitle :=
                                                         if(count($p/title) eq 1) then let $parttitle := map {"dc:title" : $p/title/text()} return map:put($refandtype, 'dts:dublincore', $parttitle) 
                                                         else              $refandtype
                                                         return 
                                                         $refTypeTitle
                                                 

(: regardless of passages sequence type (ranges as maps or items as strings) the following steps limits the number of results                                                :)
let $maximized :=if(string($max) !='') then for $p in subsequence($chunkedpassage, 1, $M) return $p else $chunkedpassage
let $cdepth := if(contains($id, 'betmasMS:')) then 3 
                                else 
                                       ( let $counts := for $div in ($text//t:div[@type eq 'textpart'], $text//t:l) 
                                        return count($div/ancestor::t:div)
                                        return
                                        max($counts)
                                        )
 let $l := if($level = '') then 1 else number($level)

return
if(count($text//t:ab//text()) le 1) then 
($config:response404JsonLD, 
map {
  "@context": "http://www.w3.org/ns/hydra/context.jsonld",
  "@type": "Status",
  "statusCode": 404,
  "title": "Not Found",
  "description": "Sorry, there is no text here to navigate."
}) 
else
 ($config:response200JsonLD,
 log:add-log-message('/api/dts/cit/' || $id, sm:id()//sm:real/sm:username/string() , 'dts'),
        map {
    "@context": map {
        "@vocab": "https://www.w3.org/ns/hydra/core#",
        "dc": "http://purl.org/dc/terms/",
        "dts": "https://w3id.org/dts/api#"
    },
    "@base": ('permanent/'||$sha||"/dts/api/document/"),
    "@id": ('permanent/'||$sha||'/api/dts/navigation?id='|| $id),
    "dts:citeDepth" : $cdepth,
    "dts:level" : $l,
    "dts:citeType": $ctype,
    "dc:hasVersion" : dts:fileingitCommits($id, $BMid, 'navigation'),
    "dts:passage" : ('permanent/'||$sha||'/'||'dts/api/document?id=' || $id||'{&amp;ref}{&amp;start}{&amp;end}'),
    "member": $maximized
})
         
};


(:~ called if the collection api path is requested without an indication of a precise betamasaheft id. returns either the main collection 
: entry point or one of the two main collections, manuscripts or works in which case it will call dts:mainColl :)
declare function persdts:Coll($id, $page, $nav, $sha){

 if($id = $availableCollectionIDs) then (
 $config:response200JsonLD,
 switch($id) 
case 'https://betamasaheft.eu/textualunits' return
dts:mainColl($id, $countW, $w, $page, $nav)
 case 'https://betamasaheft.eu/narrativeunits' return
dts:mainColl($id, $countN, $n, $page, $nav)
case 'https://betamasaheft.eu/transcriptions' return
dts:mainColl($id, $countMS, $ms, $page, $nav)
default return
map {
    "@context": $dts:context,
    "@id": $id,
    "@type": "Collection",
    "totalItems": 2,
    "title": "Beta maṣāḥǝft",
    "description" : "The project Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea (Schriftkultur des christlichen Äthiopiens: eine multimediale Forschungsumgebung) is a long-term project funded within the framework of the Academies' Programme (coordinated by the Union of the German Academies of Sciences and Humanities) under survey of the Akademie der Wissenschaften in Hamburg. The funding will be provided for 25 years, from 2016–2040. The project is hosted by the Hiob Ludolf Centre for Ethiopian Studies at the University of Hamburg. It aims at creating a virtual research environment that shall manage complex data related to predominantly Christian manuscript tradition of the Ethiopian and Eritrean Highlands.",
    "dts:dublincore": map {
        "dc:publisher": ["Akademie der Wissenschaften in Hamburg", "Hiob-Ludolf-Zentrum für Äthiopistik"],
        "dc:description": [
            map {
                "@lang": "en",
                "@value": "The project Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea (Schriftkultur des christlichen Äthiopiens: eine multimediale Forschungsumgebung) is a long-term project funded within the framework of the Academies' Programme (coordinated by the Union of the German Academies of Sciences and Humanities) under survey of the Akademie der Wissenschaften in Hamburg. The funding will be provided for 25 years, from 2016–2040. The project is hosted by the Hiob Ludolf Centre for Ethiopian Studies at the University of Hamburg. It aims at creating a virtual research environment that shall manage complex data related to predominantly Christian manuscript tradition of the Ethiopian and Eritrean Highlands."
            }
        ]
    },
    "member": [
        map {
             "@id" : "https://betamasaheft.eu/textualunits",
             "title" : "Beta maṣāḥǝft Textual Units",
             "description": "Collection of textual units of the Ethiopic tradition",
             "@type" : "Collection"
        },
         map {
             "@id" : "https://betamasaheft.eu/narrativeunits",
             "title" : "Beta maṣāḥǝft Textual Units",
             "description": "Collection of narrative units of the Ethiopic tradition",
             "@type" : "Collection"
        },
        map{
             "@id" : "https://betamasaheft.eu/transcriptions",
             "title" : "Beta maṣāḥǝft Manuscripts",
             "description": "Collection of Ethiopic Manuscript trasncriptions",
             "@type" : "Collection"
        }
    ]
})
 else (
$config:response404JsonLD ,
map {
  "@context": "http://www.w3.org/ns/hydra/context.jsonld",
  "@type": "Status",
  "statusCode": 404,
  "title": "Not Found",
  "description": "Unknown Collection, try betmas for works or betmasMS for manuscripts"
})

};
declare
%rest:GET
%rest:path("/BetMas/permanent/{$sha}/api/dts/collections")
%rest:query-param("id", "{$id}",  "")
%rest:query-param("page", "{$page}", 1)
%rest:query-param("nav", "{$nav}", "children")
%output:method("json")
function persdts:Collection($id as xs:string*,$page as xs:integer*,$nav as xs:string*,$sha as xs:string*) {
if($id = '') then (
 <rest:response>
  <http:response status="302">
    <http:header name="location" value="/permanent/{$sha}/api/dts/collections?id=https://betamasaheft.eu"/>
  </http:response>
</rest:response>
) else
if(matches($id, '(https://betamasaheft.eu/)?(textualunits/|narrativeunits/|transcriptions/)?([a-zA-Z\d]+)?(:)?(((\d+)(\w)?(\w)?((@)([\p{L}]+)(\[(\d+|last)\])?)?)?(\-)?((\d+)(\w)?(\w)?((@)([\p{L}]+)(\[(\d+|last)\])?)?)?)')) then
let $parsedURN := dts:parseDTS($id)
return
if (matches($parsedURN//s:group[@nr eq 3], '[a-zA-Z\d]+'))
then (
                let $specificID := $parsedURN//s:group[@nr eq 3]/text() 
                return persdts:CollMember($id, $specificID, $page, $nav, $sha))
else
(
$config:response400 ,
map {
  "@context": "http://www.w3.org/ns/hydra/context.jsonld",
  "@type": "Status",
  "statusCode": 400,
  "title": "Not Found",
  "description": " Resource requested is not available (versioned collection)"}
)

else 
(
$config:response400 ,
let $error := $id|| "is not a valid URN pattern"
return
map {
  "@context": "http://www.w3.org/ns/hydra/context.jsonld",
  "@type": "Status",
  "statusCode": 400,
  "title": "Not Found",
  "description": " Resource requested is not found ", "error": $error}
)
};


declare function persdts:CollMember($id, $bmID, $page, $nav, $sha){
let $doc := persdts:fileingit($id, $bmID, $sha)
let $eds := $doc//t:div[@type eq 'edition']
let $document := if(count($eds) gt 1) then (if($eds[@xml:id = 'traces']) then $eds[@xml:id = 'traces'] else $eds[1]) else $doc//t:div[@type eq 'edition']
return
if(count($doc) eq 1) then (
$config:response200JsonLD,
let $shortid:=substring-before($id, concat(':',$bmID))
let $memberInfo := persdts:member($shortid,$document, $sha)
let $addcontext := map:put($memberInfo, "@context", $dts:context)
let $addnav := if($nav = 'parent') then 
let $parent :=if($doc/@type eq 'mss') then 
        map{
             "@id" : "https://betamasaheft.eu/transcriptions",
             "title" : "Beta maṣāḥǝft Manuscripts",
             "description": "Collection of Ethiopic Manuscript trasncriptions",
             "@type" : "Collection"
        }
        else if($doc/@type eq 'narr') then 
        map{
             "@id" : "https://betamasaheft.eu/narrativeunits",
             "title" : "Beta maṣāḥǝft Narrative Units",
             "description": "Collection of narrative units of the Ethiopic tradition",
             "@type" : "Collection"
        }
        else map {
             "@id" : "https://betamasaheft.eu/textualunits",
             "title" : "Beta maṣāḥǝft Textual Units",
             "description": "Collection of literary textual units of the Ethiopic tradition",
             "@type" : "Collection"
        }
return
map:put($addcontext, "member", $parent) 
else $addcontext
return 
$addnav
) 
else
($config:response400JsonLD ,
map {
  "@context": "http://www.w3.org/ns/hydra/context.jsonld",
  "@type": "Status",
  "statusCode": 400,
  "title": "Bad Request",
  "description": "There is none or too many "||$bmID
}
)

};

(:~ produces the information needed for each member of a collection :)
declare function persdts:member($collURN,$document, $sha) as map(*){
if(not($document))
then <rest:response>
        <http:response
            status="204">
                
            <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"
                    />
        </http:response>
    </rest:response>
else 
let $doc := root($document)
let $id := string($doc//t:TEI/@xml:id)
let $title := titles:printTitleMainID($id)
let $description := if(contains($collURN, 'MS')) then 'The transcription of manuscript '||$title||' in Beta maṣāḥǝft ' else 'The abstract textual unit '||$title||' in Beta maṣāḥǝft. '  || normalize-space(string-join(string:tei2string($doc//t:abstract), ''))
let $dc := dts:dublinCore($id)
let $computed := if(contains($collURN, 'MS')) then () else 
(for $witness in $persdts:collection-rootMS//t:title[@ref eq  $id]
          let $root := root($witness)/t:TEI/@xml:id
          group by $groupkey := $root
          return string($groupkey))
let $declared := if(contains($collURN, 'MS')) then () else 
for $witness in $doc//t:witness/@corresp return string($witness)
let $witnesses := ($computed, $declared)
let $distinctW := for $w in config:distinct-values($witnesses) return 
                            map { "fabio:isManifestationOf" : "https://betamasaheft.eu/" || $w,
                            "@id" : if(starts-with($w, 'http')) then $w else ("https://betamasaheft.eu/" || $w),
                                      "@type" : "lawd:AssembledWork"}
                                      
let $dcAndWitnesses := if(count($distinctW) gt 0) then map:put($dc, 'dc:source', $distinctW) else $dc
let $DcSelector := 
if(contains($collURN, 'MS')) then $dc else $dcAndWitnesses
(:$dc:)
let $resourceURN := $collURN || ':' || $id
let $versions := dts:fileingitCommits($resourceURN, $id, 'collections')
let $DcWithVersions :=  map:put($DcSelector, "dc:hasVersion", $versions) 
let $ext := dts:extension($id)
let $haspart := dts:haspart($id)
let $manifest := if($doc//t:idno[@facs[not(starts-with(.,'http'))]]) 
                    then 
                        (:from europeana data model specification, taken from nomisma, not sure if this is correct in json LD:)
                        ( map {'@id' : ($config:appUrl ||"/manuscript/"|| $id || '/viewer'),
                                        '@type' : 'edm:WebResource',
                                        "svcs:has_service" : map{'@id' : "https://betamasaheft.eu/api/iiif/"||$id||"/manifest",
                                                                                            '@type' : 'svcs:Service',
                                                                                            "dcterms:conformsTo": "http://iiif.io/api/image",
                                                                                            "doap:implements": "http://iiif.io/api/image/2/level1.json"
                                                                                             }
                                      }
                        )
                       else if($doc//t:idno[@facs[starts-with(.,'http')]]) 
                    then 
                        (:from europeana data model specification, taken from nomisma, not sure if this is correct in json LD:)
                        ( map {'@id' : string($doc//t:idno/@facs),
                                        '@type' : 'edm:WebResource',
                                        "svcs:has_service" : map{'@id' : string($doc//t:idno/@facs),
                                                                                            '@type' : 'svcs:Service',
                                                                                            "dcterms:conformsTo": "http://iiif.io/api/image",
                                                                                            "doap:implements": "http://iiif.io/api/image/2/level1.json"
                                                                                             }
                                      }
                        )
                        else ()
let $addmanifest := if (count($manifest) ge 1) then map:put($ext, "foaf:depiction", $manifest) else $ext
let $parts := if(count($haspart) ge 1) then map:put($addmanifest, 'dcterms:hasPart', $haspart) else $addmanifest

let $dtsPass := "/permanent/"||$sha||"/api/dts/document?id=" || $resourceURN
let $dtsNav := "/permanent/"||$sha||"/api/dts/navigation?id=" || $resourceURN
let $download := "https://betamasaheft.eu/tei/" || $id || '.xml'
let $citeDepth :=  if(contains($collURN, 'MS')) then 3 else let $counts := for $div in ($document//t:div[@type eq 'textpart'], $document//t:l) return count($div/ancestor::t:div)
return max($counts)
let $teirefdecl := if(contains($collURN, 'MS')) then 
[ map{
                 "dts:citeType": "folio",
                    "dts:citeStructure": [
                       map {
                            "dts:citeType": "page",
                             "dts:citeStructure": [
                       map {
                            "dts:citeType": "column"
                        }
                  ]
             }
          ]
     }
]

else
[
dts:nestedDivs($document//t:div[@type eq 'edition'])
            ]
let $c := count($document//t:div[@type eq 'edition']//t:ab//text())
let $all := map{
             "@id" : $resourceURN,
              "ecrm:P1_is_identified_by": map {
        "rdfs:label": $resourceURN,
        "ecrm:P2_has_type": 'DTS URN'
   },
             "title" : $title,
             "description": $description,
             "@type" : "Resource",
             "totalItems": 0,
             "dts:dublincore": $DcWithVersions ,
            "dts:download": $download,
            "dts:citeDepth": $citeDepth,
            "dts:citeStructure": $teirefdecl
        }
let $ext :=         if(count($parts) ge 1) then  map:put($all,"dts:extensions",$parts) else $all
let $pass :=  map:put($ext, "dts:passage", $dtsPass) 
let $nav := map:put($pass, "dts:references", $dtsNav)
        return
        $nav
         
};

declare function persdts:fileingit($id, $bmID, $sha){
let $collection := if(contains($id, 'betmasMS')) then 'Manuscripts' else 'Works'
let $permapath := replace(persdts:capitalize-first(substring-after(base-uri($persdts:collection-root/id($bmID)[self::t:TEI]), '/db/apps/BetMasData/')), $collection, '')
return 
doc('https://raw.githubusercontent.com/BetaMasaheft/' || $collection || '/'||$sha||'/'|| $permapath)//t:TEI
};
