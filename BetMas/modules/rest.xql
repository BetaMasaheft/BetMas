xquery version "3.1" encoding "UTF-8";
(:~
 : module with all the main functions which can be called by the API.
 : 
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)
module namespace api = "https://www.betamasaheft.uni-hamburg.de/BetMas/api";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMas/modules/log.xqm";
import module namespace all="https://www.betamasaheft.uni-hamburg.de/BetMas/all" at "xmldb:exist:///db/apps/BetMas/modules/all.xqm";
import module namespace dts="https://www.betamasaheft.uni-hamburg.de/BetMas/dts" at "xmldb:exist:///db/apps/BetMas/modules/dts.xql";
import module namespace editors="https://www.betamasaheft.uni-hamburg.de/BetMas/editors" at "xmldb:exist:///db/apps/BetMas/modules/editors.xqm";
import module namespace wiki="https://www.betamasaheft.uni-hamburg.de/BetMas/wiki" at "xmldb:exist:///db/apps/BetMas/modules/wikitable.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace kwic = "http://exist-db.org/xquery/kwic"
    at "resource:org/exist/xquery/lib/kwic.xql"; 

import module namespace sparql="http://exist-db.org/xquery/sparql" at "java:org.exist.xquery.modules.rdf.SparqlModule";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMas/string" at "xmldb:exist:///db/apps/BetMas/modules/tei2string.xqm";

(: namespaces of data used :)
declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace dcterms = "http://purl.org/dc/terms";
declare namespace saws = "http://purl.org/saws/ontology";
declare namespace cmd = "http://www.clarin.eu/cmd/";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace s = "http://www.w3.org/2005/xpath-functions";
declare namespace sr = "http://www.w3.org/2005/sparql-results#";
declare namespace marc = "http://www.loc.gov/MARC21/slim";

import module namespace http="http://expath.org/ns/http-client";

(: For REST annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";

declare variable $api:response200 := $config:response200;
declare variable $api:response404 := $config:response404;

declare variable $api:response200Json := $config:response200Json;
        
declare variable $api:response200XML := $config:response200XML;

declare variable $api:response400 := $config:response400;
        
declare variable $api:response400XML := $config:response400XML;

 declare function api:stringDates($nodes){
            let $strings := for $d in $nodes return string:tei2string($d) 
            return string-join($strings, ', ')
            };
            
    (:~ given an institution or place id checks the marc records from Vatican Library for relevant related data :) 
declare
%rest:GET
%rest:path("/BetMas/api/Chojnacki/{$id}")
%output:method("json")
function api:allChojnacki($id  as xs:string*){
let $Chojnacki := collection('/db/apps/BetMas/data/Chojnacki')//marc:record[descendant::marc:subfield[@code="a"][. = $id ]]
let $ChojnackItems := for $Choj in $Chojnacki
                                            let $DigiVatID := $Choj//marc:datafield[@tag="095"]/marc:subfield[@code="a"]/text()
                                            let $link := 'https://digi.vatlib.it/stp/detail/' || $DigiVatID
                                            let $name := string-join($Choj//marc:datafield[@tag="534"]/marc:subfield/text(), ' ')
                                       
                                       return
  map {'name' := $name, 'link' := $link}
return if (count($ChojnackItems) ge 1) then map {'total' := count($ChojnackItems), 'ChojnackItems' := $ChojnackItems}
else if (count($ChojnackItems) eq 1) then map {'total' := 1, 'ChojnackItems' := [$ChojnackItems]}
else map {'total' := 0, 'info' := 'sorry, there are no related items in the Chojnacki Collection at the Vatic Library.'}};

(:~ given a series of dts urn of witness passages, produces the json required for a request to collatex and posts it :) 
declare
%rest:POST
%rest:GET
%rest:path("/BetMas/api/collatex")
%rest:query-param("dts", "{$dts}", "")
%rest:query-param("format", "{$format}", "tei+xml")
function api:collatex($dts  as xs:string*,$format  as xs:string*){
$api:response200,
let $urns := for $u in tokenize($dts, ',') return $u
return

if(count($urns) le 1) 

then (<info>please provide at least 2 dts urns separated with comma</info>)  else(
  
                                         
   let $body :=   dts:getCollatexBody($urns)
     let $req :=
        <http:request
        http-version="1.1"
            href="{xs:anyURI('http://localhost:7369/collate')}"
            method="POST">
            <http:header
                name="Conten-Type"
                value="application/json"/>
                <http:header name="Access-Control-Allow-Origin" value="*"/>
            <http:header name="Accept" value="application/{$format}"/>
            
                <http:body media-type="text" method="text" indent="yes">{$body}</http:body>
        </http:request>
let $post:=          hc:send-request($req)[2]
let $decoded := if(contains($format, 'xml')) then $post else util:base64-decode($post)
return 
$decoded
    
    )
};

    (:~ given a role, search other attestations of it and print the persName around them and related infos :) 
declare
%rest:GET
%rest:path("/BetMas/api/quotations/{$text}/{$passage}")
%output:method("json")
function api:allquotations($text  as xs:string*,$passage  as xs:string*){
let $quotations := collection($config:data-root)//t:cit[t:ref[contains(@cRef, $text)]]
let $thispassage := for $quote in $quotations[t:ref[contains(substring-after(@cRef, concat($text, ':')), $passage)]]
                                            let $id := string(root($quote)/t:TEI/@xml:id) 
                                          let $titlesource := titles:printTitleMainID($id)
                                           let $source := map {'id' := $id, 'title' := $titlesource} 
                                            let $t := $quote/t:quote/text()
                                            let $r := string($quote/t:ref/@cRef)
                                        return 
                                        map {'text' := $t, 'source' := $source, 'ref' := $r}
return if (count($thispassage) ge 1) then map {'total' := count($thispassage), 'quotations' := [$thispassage]} else map {'total' := 0, 'info' := 'sorry, there are no marked up quotations of this passage'}
};


    
       
       (:~ given the id of a manuscript returns the word count for eventual transcriptions of that work in the given witness :) 
declare

%rest:GET
%rest:path("/BetMas/api/WordCount/{$manuscriptID}/{$workID}")
%output:method("text")
function api:WordCount($manuscriptID  as xs:string*, $workID as xs:string*) as xs:string{
let $ms := collection($config:data-rootMS)/id($manuscriptID)
let $tit := $ms//t:title[@ref = $workID]

let $msitemID := $tit/parent::t:msItem/@xml:id

return

if($ms//t:div[contains(@corresp, $msitemID)]) then
let $div := $ms//t:div[contains(@corresp, $msitemID)]
let $count := count(tokenize(string-join($div//text(), ' '), '\W+'))
return
'word count: ' || $count
else ('word count: no transcription available')

};


declare 
%rest:GET
%rest:path("/BetMas/api/listRepositoriesName")
%output:method("html")
function api:listRepositoriesName()
{
for $i in collection($config:data-rootIn)//t:TEI/@xml:id
let $id := string($i)
let $name := base-uri($i)
let $tit := titles:printTitleMainID($id)
order by $tit
return
<option value="{$id}">{$tit}</option>
};


declare 
%rest:GET
%rest:path("/BetMas/api/cataloguesZotero")
%output:method("html")
function api:getcataloguesZotero()
{
for $catalogue in distinct-values(collection($config:data-rootMS)//t:listBibl[@type='catalogue']//t:ptr/@target)
let $xml-url := concat('https://api.zotero.org/groups/358366/items?&amp;tag=', $catalogue, '&amp;format=bib&amp;style=hiob-ludolf-centre-for-ethiopian-studies')
let $data := httpclient:get(xs:anyURI($xml-url), true(), <Headers/>)
    order by $data
return
<option value="{$catalogue}">{$data//httpclient:body}</option>
};

(:given a  id returns the attestations and cooccurring entities:)
declare

%rest:GET
%rest:path("/BetMas/api/attestations/{$type}/{$id}")
%output:method("json")
function api:attestationsofperson($id as xs:string*, $type as xs:string*)
{
let $ty := switch($type)
case 'person' return 't:persName[@ref'
case 'place' return 't:placeName[@ref'
case 'work' return 't:title[@ref'
case 'mss' return 't:ref[@type="mss"][@corresp'
case 'term' return 't:term[@key'
default return 't:persName'
let $c := collection($config:data-root)
let $attestations:= api:restWhatPointsHere($id, $c)
let $hits :=
for $att in $attestations
let $rootID := string(root($att)/t:TEI/@xml:id) 
group by $MAINID := $rootID
let $titleRoot := titles:printTitleMainID($MAINID)
let $atts := 
   for $a at $p in $att 
   let $element := $a/name()
   let $text := if($a/text()) 
                 then $a/text() 
                 else 'pointer only'
    let $cooccurringPers := ($a/preceding-sibling::t:persName,$a/following-sibling::t:persName)
    let $cooccurringPlace := ($a/preceding-sibling::t:placeName,$a/following-sibling::t:placeName)
    let $cooccurringworks := ($a/preceding-sibling::t:title,$a/following-sibling::t:title)
    let $cooccurringterm := ($a/preceding-sibling::t:term,$a/following-sibling::t:term)
    let $date := if($a/ancestor::t:item[1]//t:date) 
                  then api:stringDates($a/ancestor::t:item[1]//t:date)
                  else if($a/ancestor::t:msItem//t:date) 
                  then api:stringDates($a/ancestor::t:msItem[1]//t:date) 
                  else if($a/ancestor::t:handNote//t:date) 
                  then api:stringDates($a/ancestor::t:handNote[1]//t:date) 
                  else if($a/ancestor::t:decoNote//t:date) 
                  then api:stringDates($a/ancestor::t:decoNote[1]//t:date) 
                  else 'no date'
    let $MainRole := switch($element) 
    case 'persName' return string($a/@role)
    case 'relation' return string($a/@name)
    case 'ref' return string($a/@type)
    default return ()
let $titles := ($a/t:roleName, $a/t:addName)
let $alltitles := for $t in $titles return $t/name() || ': ' || $t/text()
let $jointitles := string-join($alltitles, ', ')
let $occpers := if(count($cooccurringPers) gt 0) then 
(let $persons := for $pers in $cooccurringPers 
let $id := if($pers/@ref) then string($pers/@ref) else 'no-id'
         let $name := 
              if($pers/text())
              then $pers/text() 
              else titles:printTitleMainID($pers/@ref)
        let $thisrole := 
              if($pers/@role) 
              then string($pers/@role) 
              else () 
       return map {'id' := $id ,'name' := $name, 'type' := $thisrole}
return 
map {'type' := 'persons', 'persons' := $persons}
)
else ()
let $occplace := if(count($cooccurringPlace) gt 0) then 
(let $places := for $place in $cooccurringPlace
let $id := if($place/@ref) then string($place/@ref) else 'no-id'
         let $name := 
              if($place/text())
              then $place/text() 
              else titles:printTitleMainID($place/@ref)
        let $thistype := 
              if($place/@type) 
              then string($place/@type)
              else () 
       return map {'id' := $id ,'name' := $name, 'type' := $thistype}
return 
map {'type' := 'places', 'places' := $places}
)
else ()
let $occwork := if(count($cooccurringworks) gt 0) then 
(let $works := for $work in $cooccurringworks 
let $id := if($work/@ref) then string($work/@ref) else 'no-id'
         let $name := 
              if($work/text())
              then $work/text() 
              else titles:printTitleMainID($work/@ref)
        
       return map {'id' := $id , 'name' := $name}
return 
map {'type' := 'works', 'works' := $works}
)
else ()
let $occterm := if(count($cooccurringterm) gt 0) then 
(let $terms := for $term in $cooccurringterm 
let $id := if($term/@key) then string($term/@key) else 'no-id'
          let $name := 
              if($term/text() and $term/@key)
              then $term/text()
              else if (not($term/@key)) then $term/text()
              else titles:printTitleMainID($term/@key)
       
       return map {'id' := $id ,'name' := $name}
return 
map {'type' := 'terms', 'terms' := $terms}
)
else ()
let $occurrences := ($occpers, $occplace, $occwork, $occterm)



return 
map {'position' := $p, 
'role' := $MainRole,
'text' := $text,
'element' := $element,
'date' := $date,
'jointitles' := $jointitles,
'occurrences' := $occurrences
}


return 
map {'result' := $atts, 'title' := $titleRoot, 'id' := $MAINID }

return


($api:response200Json,
map {'query' := $id, 'results' := $hits }

)
};

(:given a work id returns the witnesses of works in which this is contained:)
declare

%rest:GET
%rest:path("/BetMas/api/witnessesOfContainer/{$id}")
%output:method("json")
function api:witnessesOfContainerWork($id as xs:string*){
let $corresps := collection($config:data-rootW)//t:div[@type ='textpart'][@corresp = $id]
for $c in $corresps 
let $workid := string(root($c)/t:TEI/@xml:id )
let $witnesses := collection($config:data-rootMS)//t:title[contains(@ref, $workid)]
let $witnessesID := for $w in $witnesses let $wid :=  string(root($w)/t:TEI/@xml:id ) return  titles:printTitleMainID($wid)
let $tit := titles:printTitleMainID($workid)
return 
map {'containerWork' := $tit,
'witnesses' := distinct-values($witnessesID)
}
};

(:displaies on the hompage the totals of the portal:)
declare

%rest:GET
%rest:path("/BetMas/api/count")
%output:method("json")
function api:count(){
 ($api:response200Json,
let $total := count(collection($config:data-root))
let $totalMS := count(collection($config:data-rootMS))
let $totalInstitutions := count(collection($config:data-rootIn))
let $totalWorks := (count(collection($config:data-rootW)) + count(collection($config:data-rootN)))
let $totalPersons := count(collection($config:data-rootPr))
return 

map {
'total' := $total, 
'totalMS' := $totalMS,
'totalInstitutions' := $totalInstitutions,  
'totalWorks' := $totalWorks, 
'totalPersons' := $totalPersons
 }
 )
};

(:displaies on the hompage the totals of the portal:)
declare

%rest:GET
%rest:path("/BetMas/api/latest")
%output:method("json")
function api:latest(){
 ($api:response200Json,

let $twoweekago := current-date() - xs:dayTimeDuration('P15D')
let $changes := collection($config:data-root)//t:change[@when]
let $latests := 
    for $alllatest in $changes[xs:date(@when) > $twoweekago]
    order by xs:date($alllatest/@when) descending
    return $alllatest

for $latest at $count in subsequence($latests, 1, 20)
let $id := string(root($latest)/t:TEI/@xml:id)
let $title := titles:printTitle($latest)
let $when := string($latest/@when)
let $who := editors:editorKey($latest/@who)
let $what := $latest/text()
return
map { 'id' := $id,
'title' := $title,
'when' := $when,
'who' := $who,
'what' := $what
}
 )
};



declare
%rest:GET
%rest:path("/BetMas/api/academics")
%output:method("json")
function api:academics(){
for $academic in collection($config:data-rootPr)//t:occupation[@type='academic']
let $title := normalize-space(string(titles:printTitle($academic)))
let $zoterurl := 'https://www.zotero.org/groups/ethiostudies/items/q/'||xmldb:encode-uri($title)
let $root := root($academic)
let $p := $academic/ancestor::t:person
let $id := $root//t:TEI/@xml:id
let $date := ($p//t:*[@notBefore or @notAfter or @when], $p//t:floruit)
let $dates := ($date/@notBefore, $date/@notAfter, $date/@when)
let $years := for $d in $dates return if (contains(string($d), '-')) then substring-before(string($d),'-') else string($d)
let $mindate := min($years)
let $d-d := ($mindate || ' - '||max($years))
let $bio := normalize-space(string-join(string:tei2string($p//t:floruit), ' '))
let $academictext := normalize-space(string-join(string:tei2string($academic)))
let $wikidata := if(starts-with($p/@sameAs, 'Q')) then wiki:wikitable(string($p/@sameAs)) else ('No Wikidata ID')
order by $mindate
return
map {
'id' := string($id),
'title' := $title,
'text' := $academictext,
'dates' := $d-d,
'bio' := $bio,
'zoturl' := $zoterurl,
'wd' := $wikidata
}

};

  
(:~transforms into string text a single part of a tei file, e.g. a single node which contains many references to persons, places etc.:)
declare
%rest:GET
%rest:path("/BetMas/api/string/{$id}")
%rest:query-param("element", "{$element}", "")
%output:method("text")
function api:teiNode2string($id as xs:string, $element as xs:string*){

    ($api:response200,
    let $file := api:get-tei-by-ID($id)
    let $string := for $e in $file//t:*[name() = $element]
    return
    string:tei2string($e/node())
    return
    normalize-space(string-join($string, ''))
    )
};


(:~retrives a single part of a tei file, e.g. a single node:)
declare
%rest:GET
%rest:path("/BetMas/api/xmlpart/{$id}")
%rest:query-param("element", "{$element}", "")
%output:method("xml")
%test:args("BNFet102", "additions") 
%test:assertXPath('//*:item')
function api:teipart($id as xs:string, $element as xs:string*){

    ($api:response200,
    let $file := api:get-tei-by-ID($id)
    for $e in $file//t:*[name() = $element]
    return
    <fragment>{
    $e/node()
    }</fragment>
    )
};

(:~retrives a single part of a tei file, e.g. a single node:)
declare
%rest:GET
%rest:path("/BetMas/api/enrichMe/{$id}/{$anchor}")
%output:method("json")
function api:teipart($id as xs:string, $anchor as xs:string*){

    ($api:response200Json,
    let $file := api:get-tei-by-ID($id)
    let $node := $file//id($anchor)
    let $name :=  $node/name()
    let $NodeMap :=  map {}
    let $NodeMapwithxmllang := if($node/@xml:lang) then map:put($NodeMap, 'xml:lang', string($node/@xml:lang)) else $NodeMap
    let $NodeMapwithtitle := if($node/t:title) then 
                               let $titString := if ($node/t:title/@ref) then 
                                                                     let $titRef := string($node/t:title/@ref)
                                                                     return titles:printTitleMainID($titRef) 
                                                              else $node/t:title/text() 
                              return map:put($NodeMapwithxmllang, 'title', $titString[1]) 
                              else $NodeMapwithxmllang
  let $NodeMapwithdate := if($node/t:date) then 
                               let $dateString := string-join(string:tei2string($node/t:date), ', ')
                              return map:put($NodeMapwithtitle, 'date', $dateString) 
                              else $NodeMapwithtitle
  let $NodeMapwithbibl := if($node//t:bibl) then 
                              let $bibstrings := for $b in $node//t:bibl return string:tei2string($b)
                              let $biblString := string-join($bibstrings, '; ')
                              return map:put($NodeMapwithdate, 'bibliography', $biblString) 
                              else $NodeMapwithdate
 let $NodeMapwithnote := if($node/t:note) then 
                              let $noteString := string-join(string:tei2string($node/t:note), '; ')
                              return map:put($NodeMapwithbibl, 'note', $noteString) 
                              else $NodeMapwithbibl
 let $NodeMapwithdesc := if($node/t:desc/text()) then 
                              let $descString := string-join(string:tei2string($node/t:desc), '; ')
                              return map:put($NodeMapwithnote, 'desc', $descString) 
                              else $NodeMapwithnote
 let $NodeMapwithdesctype := if($node/t:desc/@type) then 
                              let $desctypeString := titles:printTitleMainID(string($node/t:desc/@type))
                              return map:put($NodeMapwithdesc, 'type', $desctypeString) 
                              else $NodeMapwithdesc
 let $NodeMapwithdecotype := if($node/name() = 'decoNote') then 
                              let $decotypeString := string($node/@type)
                              return map:put($NodeMapwithdesctype, 'deco type', $decotypeString) 
                              else $NodeMapwithdesctype
 let $NodeMapwithlinks := if($node//t:*[@ref ] or $node//t:term or $node//t:ref) then 
                              let $named := for $ne in $node//t:*[@ref] return titles:printTitleID($ne/@ref) || (if($ne/@role)then ' ('||string($ne/@role)||')' else ())
                              let $terms := for $t in $node//t:term/@key return titles:printTitleMainID($t)
                              let $refs :=for $r in $node//t:ref return string:tei2string($r)
                              let $all := ('Named Entities: ' ||string-join($named, ', ')||' | Terms: ' || string-join($terms, ', ')||' | References: ' || string-join($refs, ', '))
                              return map:put($NodeMapwithdecotype, 'links', $all) 
                              else $NodeMapwithdecotype
let $NodeMapwithscript := if($node/@script ) then 
                              let $scriptString := string($node/@script)
                              return map:put($NodeMapwithlinks, 'script', $scriptString) 
                              else $NodeMapwithlinks
                              
    return 
           $NodeMapwithlinks
    
    )
};


(:~retrives a single part of a tei file given a URI as formatted in the RDF, e.g. a single node:)
declare
%rest:GET
%rest:path("/BetMas/api/{$id}/{$type}/{$subid}")
%output:method("xml")
%test:args("BNFet102", "addition", "a1") 
%test:assertXPath('//*:item')
function api:teipartbyURI($id as xs:string, $type as xs:string, $subid as xs:string){
 let $element := switch($type)
    case 'addition' return 'item'
    case 'msitem' return 'msItem'
    case 'mspart' return 'msPart'
    case 'msfrag' return 'msFrag'
    case 'quire' return 'item'
    case 'hand' return 'handDesc'
    case 'layout' return 'layout'
    case 'binding' return 'decoNote'
    case 'decoration' return 'decoNote'
        default return 'nomatch'
 return     
     if ($element = 'nomatch') then 
         ($api:response404) else
    ($api:response200,
   
    let $file := api:get-tei-by-ID($id)
    for $e in $file//id($subid)[name() = $element]
    return
    <fragment xmlns="http://betamasaheft.eu/" source="http://betamasaheft.eu/{$id}">{
    $e
    }</fragment>
    )
};

(:~gets the collection name from one of the standard values of the attribute type in the TEI element :)
declare 
%test:arg("type", "mss") %test:assertEquals('manuscripts')
function api:switchcol($type){
    
    switch($type)
        case 'work' return 'works'
        case 'narr' return 'narratives'
        case 'pers' return 'persons'
        case 'place' return 'places'
        case 'ins' return 'institutions'
        case 'auth' return 'authority-files'
        default return 'manuscripts'
    
};

(:~gets the formatted content of an addition in an item, given the id of the file and that of the addition item :)
declare
%rest:GET
%rest:path("/BetMas/api/additions/{$id}/addition/{$addID}")
%output:method("xml")
%test:args("BAVet1", "a4")
%test:assertXPath("//span[@class='word']")
function api:additiontext($id as xs:string*, $addID as xs:string*){
let $log := log:add-log-message('/api/additions/'||$id||'/addition/'||$addID, xmldb:get-current-user(), 'REST')
let $c := collection($config:data-root)
let $entity := $c//id($id)
let $a := $entity//t:item[@xml:id = $addID]
return
transform:transform($a,  'xmldb:exist:///db/apps/BetMas/xslt/q.xsl', ())

    
};
 


(:~gets the a list elements with a reference to the given id in the specified collection (c) :)
declare function api:restWhatPointsHere($id as xs:string, $c){
           let $witnesses := $c//t:witness[@corresp = $id]
let $placeNames := $c//t:placeName[@ref = $id]
let $persNames := $c//t:persName[@ref = $id]
let $ref := $c//t:ref[@corresp = $id]
let $titles := $c//t:title[@ref = $id]
let $settlement := $c//t:settlement[@ref = $id]
let $region := $c//t:region[@ref = $id]
let $country := $c//t:country[@ref = $id]
let $active := $c//t:relation[@active = $id]
let $passive := $c//t:relation[@passive = $id]
let $allrefs := ($witnesses, 
        $placeNames,  
        $persNames, 
        $ref,
        $titles,
        $settlement,
        $region,
        $country,
        $active, 
        $passive)
return
for $corr in $allrefs
        return 
            $corr
            
            };

(:~gets the a json object containing an array of objects related to the given id. the array will contain the requested entity as a node and any one retrived using the function api:restWhatPointsHere() with the properties id label and group properties. it is thought to be used in combination with the edges for graph visualization :)
declare
%rest:GET
%rest:path("/BetMas/api/relations/{$id}")
%output:method("json")
function api:relNodes($id as xs:string*){

let $c := collection($config:data-root)
let $entity := $c//id($id)
let $type := $entity/@type
let $collection := api:switchcol($type)

let $localId := $id
let $thisMap := map {
        "id" := $id, 
        "label" := titles:printTitleID($id), 
        "group" := string($type)
        }

let $whatpointshere := api:restWhatPointsHere($localId, $c)

let $refs := ($entity//@ref[not(./ancestor::t:respStmt)], $entity//@active, $entity//@passive)
let $secondaryrelations := 
for $id in distinct-values($refs[.!=$localId]) return 
(:exclude empty values :)
if($id ='') then () 
else if(starts-with($id,'INS')) then () 
else if(contains($id,' ')) then () 
else 
    let $whatppointstothat := api:restWhatPointsHere($id, $c) 
    return
        (:if more than 10 items are related then it is unlikely to be relevant:)
    if(count($whatppointstothat) gt 10) then () else $whatppointstothat

let $wph := 
    let $ids := for $pointerRoot in ($whatpointshere, $secondaryrelations)
                let $refid := root($pointerRoot)/t:TEI/@xml:id
                return $refid
    let $allids :=($ids, $refs)
    let $distincts :=  distinct-values($allids)
    for $I in $distincts
    let $cleanId := if(contains($I, '#')) then substring-before($I,  '#') else $I
    let $thisI := $c//id($cleanId)[name()='TEI']
    let $rootype := $thisI[1]/@type
    let $title := if(contains($I, '#')) then titles:printTitleID($I) else titles:printTitleMainID($I)
    let $titleN := if(count($title) gt 1) then normalize-space(string-join($title, ' ')) else normalize-space($title)
    return 
      (:first return the root of the referring entity and the id in the corresp, active, passive, mutual, etc. there.:)
     map {
        "id" := $I, 
        "label" := $titleN,
        "group" := string($rootype)
        }

let $here := 
    (: from the current item to the entities it points to :)
    for $id in $refs 
    let $elem := $id/parent::t:*
    let $pN := name($elem)
        let $name := if($pN = 'relation') then string($elem/@name) else $pN
        return
    map {'from':=$localId, 
      'to':=$id/string(), 
      'label':=$name, 
      'value':=1, 
      'font':= map {'align':= 'top'}}
      let $there :=
 (:from what points here to the current item:)
      for $id in $secondaryrelations 
      let $r := root($id)/t:TEI/@xml:id
      let $refname := name($id)
      let $name := if($refname = 'relation') then string($id/@name) else $refname
      let $R := if($refname = 'witness') then string($id/@corresp) else if($refname = 'relation') then if($refs = $id/@active) then  string($id/@active) else string($id/@passive) else string($id/@ref)
        return
    map {'from':= string($r), 
      'to':=$R, 
      'label' := $name,
      'value':= 1, 
      'font':= map {'align':= 'top'}}
  let $tohere :=
 (:from what points here to the current item:)
      for $id in $whatpointshere 
      let $r := root($id)/t:TEI/@xml:id
      let $refname := name($id)
      let $name := if($refname = 'relation') then string($id/@name) else $refname
     
        return
    map {'from':= string($r), 
      'to':=$localId, 
      'label' := $name,
      'value':= 1, 
      'font':= map {'align':= 'top'}}
      
      let $edges := ($here, $there, $tohere)
      let $idswph :=  for $x in $wph return $x('id')
      let $nodes := if($idswph = $id) then $wph else ($thisMap, $wph)
return
(:returns the title and id of the entities referring to this entity or entity referring to those pointing to the entity:)
  ($api:response200Json,
 map {'nodes' :=  $nodes,
 'edges' :=  $edges,
     'cN' := count($nodes),
     'cE' := count($edges)
 })
};


(:~gets an array of objects in JSON, containing the id and title of resources in the db which have the same keywords or value for a typed element. :)
declare
%rest:GET
%rest:path("/BetMas/api/sharedKeyword/{$keyword}")
%rest:query-param("element", "{$element}", "persName")
%output:method("json")
function api:SharedKeyword(
$keyword as xs:string*, $element as xs:string*) {
let $log := log:add-log-message('/api/sharedKeyword/'||$keyword, xmldb:get-current-user(), 'REST')

let $attr := switch($element) 
                            case 'persName' return 'ref' 
                            case 'keywords' return 'key'
                            case 'material' return 'key'
                            case 'script' return 'script'
                            case 'form' return 'form'
                            case 'attributed author' return 'active'
                            case 'author' return 'passive'
                            case 'settlement' return 'ref'
                            case 'region' return 'ref'
                            case 'country' return 'ref'
                            case 'type' return 'type'
                            case 'role' return 'type'
                            case 'faith' return 'type'
                            case 'occupation' return 'type'
                            default return 'ref'
let $elementName := switch($element) 
                             case 'persName' return 'persName' 
                            case 'keywords' return 'term'
                            case 'material' return 'supportDesc/t:material'
                            case 'script' return 'handNote'
                            case 'form' return 'objectDesc'
                            case 'attributed author' return 'relation'
                            case 'author' return 'relation'
                            case 'settlement' return 'settlement'
                            case 'region' return 'region'
                            case 'country' return 'country'
                            case 'type' return 'place'
                            case 'role' return 'roleName'
                            case 'faith' return 'faith'
                            case 'occupation' return 'occupation'
                            default return 'persName'
let $buildQuery := 'collection($config:data-root)//t:TEI[descendant::t:' || $elementName ||'[@' || $attr || "='" || $keyword || "']]"
let $query :=  util:eval($buildQuery)
let $total := count($query)
let $hits := for $hit in $query
                let $id := string($hit/@xml:id)
                let $title := try{titles:printTitleMainID($id)} catch * {('no title for ' || $id)}
               
          return
            map {
                'id' : $id,
                'title' : $title
                    }

return 
($api:response200Json,
map {
'hits' := $hits,
'total' := $total
})
};


(:~ searches the content of the ids and returns a JSON object containing an array of objects with possible matches. id here can be a full id or any part of it. :)
declare 
%rest:GET
%rest:path("/BetMas/api/idlookup")
%rest:query-param("id", "{$id}", "")
%output:method("json")
%test:arg('id', 'dsapdsjapo') %test:assertEquals('<rest:response xmlns:rest="http://exquery.org/ns/restxq"><http:response xmlns:http="http://expath.org/ns/http-client" status="200"><http:header name="Content-Type" value="application/json; charset=utf-8"/><http:header name="Access-Control-Allow-Origin" value="*"/></http:response></rest:response>','<json:value xmlns:json="http://www.json.org"><json:value json:array="true"><info>No results, sorry</info></json:value></json:value>')
function api:IDSlookup($id as xs:string*) {
log:add-log-message('/api/idlookup?id=' || $id, xmldb:get-current-user(), 'REST'),

let $query := (
collection('/db/apps/BetMas/data/')/t:TEI[contains(@xml:id, $id)],
collection('/db/apps/BetMas/data/')//t:msPart[contains(@xml:id, $id)],
collection('/db/apps/BetMas/data/')//t:msItem[contains(@xml:id, $id)],
collection('/db/apps/BetMas/data/')//t:title[contains(@xml:id, $id)],
collection('/db/apps/BetMas/data/')//t:div[contains(@xml:id, $id)])
 let $results := for $hit in $query
 let $i := string($hit/@xml:id)
(: let $rootID := string(root($hit)/t:TEI/@xml:id):)
(: let $title := if ($i = $rootID) then titles:printTitleID($i) else api:printSubtitle(root($hit),$i):)
        return
        map {'id' := $i}
     
let $c := count($query)
return
    if (count($query) gt 0) then
        ($api:response200Json,
        map {
            'items' : $results,
           'total' : $c
        })
    else
        ($api:response200Json,
        <json:value>
            <json:value
                json:array="true">
                <info>No results, sorry</info>
            </json:value>
        </json:value>)

};


(:~ returns the relation element with the author attribution :)

declare 
%rest:GET
%rest:path("/BetMas/api/{$id}/author")
%output:method("xml")
%test:arg("id","LIT1032Agains") %test:assertXPath("//@name[. = 'saws:isAttributedToAuthor']")
%test:arg("id","BAVet1") %test:assertEquals('<rest:response xmlns:rest="http://exquery.org/ns/restxq"><http:response xmlns:http="http://expath.org/ns/http-client" status="400"><http:header name="Content-Type" value="application/xml; charset=utf-8"/></http:response></rest:response>','<sorry>no info</sorry>')
function api:getauthorfromrelation($id as xs:string*) {
let $item := collection('/db/apps/BetMas/data/works/')//id($id)
return 

if($item//t:relation[@name = 'saws:isAttributedToAuthor']) then (

log:add-log-message('/api/' || $id || '/author', xmldb:get-current-user(), 'REST'),
$api:response200XML,
        $item//t:relation[@name = 'saws:isAttributedToAuthor']
        )
        else 
        (
        $api:response400XML,
        <sorry>no info</sorry>
        )
};



(:~ returns a JSON object with the aligned known clavis ids :)
declare
%rest:GET
%rest:path("/BetMas/api/clavis/{$id}")
%output:method("json")
function api:ClavisbyID($id as xs:string*) {

(:results from PAThs
results from BM interroga bibl con id clavis e titolo.
se interrogato da titolo da gli id, altrimenti per id da gli altri id e il titolo

:)

    let $log := log:add-log-message('/api/clavis/' || $id , xmldb:get-current-user(), 'REST')
                    let $root := api:get-tei-by-ID($id)
                    let $id := string($root/@xml:id)
                    let $title := titles:printTitleMainID($id)
                    let $clavisBibl := $root//t:listBibl[@type='clavis']
                    let $CC := $clavisBibl/t:bibl[@type='CC']/t:citedRange/text()
                    let $CPG := $clavisBibl/t:bibl[@type='CPG']/t:citedRange/text()
                    let $CANT := $clavisBibl/t:bibl[@type='CANT']/t:citedRange/text()
                    let $CAVT := $clavisBibl/t:bibl[@type='CAVT']/t:citedRange/text()
                    let $BHO := $clavisBibl/t:bibl[@type='BHO']/t:citedRange/text()
                    let $BHL := $clavisBibl/t:bibl[@type='BHL']/t:citedRange/text()
                    let $syriaca := $clavisBibl/t:bibl[@type='syriaca']/t:citedRange/text()
                    let $clavisIDS := map {
                    "CC":=  $CC,
                    "CPG":=  $CPG,
                    "CANT":=  $CANT,
                    "CAVT":=  $CAVT,
                    "BHO":=  $BHO,
                    "BHL":=  $BHL,
                    "syriaca":=  $syriaca
                    }
                    
                    return
                        ( $api:response200Json,
                        map {
                            "CAe" := $id,
                            "title" := $title,
                            "clavis" := $clavisIDS                
                        })
                        
};


(:~ returns a JSON object with the aligned known clavis ids :)
declare
%rest:GET
%rest:path("/BetMas/api/clavis/all")
%rest:query-param("type", "{$type}", "")
%output:method("json")
function api:ClavisALL($id as xs:string*, $type as xs:string*) {

(:results from PAThs
results from BM interroga bibl con id clavis e titolo.
se interrogato da titolo da gli id, altrimenti per id da gli altri id e il titolo

:)
(:
    let $log := log:add-log-message('/api/clavis/' || $id , xmldb:get-current-user(), 'REST')
               :)  
               let $bibl := if ($type != '') then "[t:bibl[@type = '" ||$type||"']]" else ()
               let $path := util:eval("collection($config:data-rootW)//t:listBibl[@type='clavis']" || $bibl)
              let $results := for $work in $path
                    let $root := root($work)
                    let $id := string($root/t:TEI/@xml:id)
                    let $title := titles:printTitleMainID($id)
                    let $CC := $work/t:bibl[@type='CC']/t:citedRange/text()
                    let $CPG := $work/t:bibl[@type='CPG']/t:citedRange/text()
                    let $CANT := $work/t:bibl[@type='CANT']/t:citedRange/text()
                    let $CAVT := $work/t:bibl[@type='CAVT']/t:citedRange/text()
                    let $BHO := $work/t:bibl[@type='BHO']/t:citedRange/text()
                    let $BHL := $work/t:bibl[@type='BHL']/t:citedRange/text()
                    let $syriaca := $work/t:bibl[@type='syriaca']/t:citedRange/text()
                    let $clavisIDS := map {
                    "CC":=  $CC,
                    "CPG":=  $CPG,
                    "CANT":=  $CANT,
                    "CAVT":=  $CAVT,
                    "BHO":=  $BHO,
                    "BHL":=  $BHL,
                    "syriaca":=  $syriaca
                    }
                    
                    return
                        map {
                            "CAe" := $id,
                            "CAeN" := substring($id, 4,4),
                            "CAeURL" := 'http://betamasaheft.eu/works/' || $id || '/main',
                            "title" := $title,
                            "clavis" := $clavisIDS                
                        }
                        
                        return
                         ( $api:response200Json,
                          map {'results' := $results, 'total' := count($results)}
                         )
                       
};


(:results from PAThs
results from BM interroga bibl con id clavis e titolo.
se interrogato da titolo da gli id, altrimenti per id da gli altri id e il titolo

:) 
declare
%rest:GET
%rest:path("/BetMas/api/clavis")
%rest:query-param("q", "{$q}", "")
%output:method("json")
function api:Clavis($q as xs:string*) {

let $eval-string := concat("collection('", $config:data-rootW, "')//t:title",
"[ft:query(.,'", $q, "')]")

let $log := log:add-log-message('/api/clavis?q=' || $q, xmldb:get-current-user(), 'REST')
let $hits := util:eval($eval-string)
let $hi :=   for $hit in $hits
                    let $root := root($hit)
                    let $id := string($root//t:TEI/@xml:id)
                    group by $id := $id
                    let $title := titles:printTitleMainID($id)
                    let $hitCount := count($hit)
                    let $clavisBibl := $root//t:listBibl[@type='clavis']
                    let $CC := $clavisBibl/t:bibl[@type='CC']/t:citedRange/text()
                    let $CPG := $clavisBibl/t:bibl[@type='CPG']/t:citedRange/text()
                    let $CANT := $clavisBibl/t:bibl[@type='CANT']/t:citedRange/text()
                    let $CAVT := $clavisBibl/t:bibl[@type='CAVT']/t:citedRange/text()
                    let $BHO := $clavisBibl/t:bibl[@type='BHO']/t:citedRange/text()
                    let $BHL := $clavisBibl/t:bibl[@type='BHL']/t:citedRange/text()
                    let $syriaca := $clavisBibl/t:bibl[@type='syriaca']/t:citedRange/text()
                    let $clavisIDS := map {
                    "CC":=  $CC,
                    "CPG":=  $CPG,
                    "CANT":=  $CANT,
                    "CAVT":=  $CAVT,
                    "BHO":=  $BHO,
                    "BHL":=  $BHL,
                    "syriaca":=  $syriaca
                    }
                    
                    return
                        map {
                            "CAe" := $id,
                            "title" := $title,
                            "clavis" := $clavisIDS,
                            "hits" := $hitCount                    
                        }
let $c := count($hits)
return
    if (count($hits) gt 0) then
         ( $api:response200Json,
       map {
            "items" := $hi,
            "totalhits":= $c
        
        })
    else
         ( $api:response200Json,
        <json:value>
            <json:value
                json:array="true">
                <info>No results, sorry</info>
            </json:value>
        </json:value>)
};


(:~ returns an object which includes an array of objects with data about persons to which in some resource a specific role has been assigned, for each id, canonical title and the list of resources for which he/she covers such role, are given. :)
declare
%rest:GET
%rest:path("/BetMas/api/hasrole/{$role}")
%output:method("json")
%test:arg('role', 'donor') %test:assertExists
%test:arg('role', 'scribe') %test:assertExists
function api:role($role as xs:string*) {

let $log := log:add-log-message('/api/hasrole/' || $role, xmldb:get-current-user(), 'REST')
let $cp := collection($config:data-rootPr)
let $path :=  collection($config:data-root)//t:persName[@role = $role][@ref[not(starts-with(. ,'PRS0000'))][. != 'PRS0476IHA'][. != 'PRS0204IHA']]
let $total := count($path)
let $hits := for $pwl in $path
                    let $id := string($pwl/@ref)
                   
                    group by $ID := $id
            
        return
            map {
                'pwl' : $ID,
                'title' : titles:printTitleMainID($ID),
                'hits' : count($pwl)
                    }

return 
     ( $api:response200Json,
map {
'role' := $role,
'hits' := $hits,
'total' := count($hits),
'referring' := $total
})
};


(:~ returns an object which includes an array of objects with data about persons to which in some resource a specific role has been assigned, for each id, canonical title and the list of resources for which he/she covers such role, are given. :)
declare
%rest:GET
%rest:path("/BetMas/api/hasrole/{$role}/{$ID}")
%output:method("json")
%test:arg('role', 'donor') %test:assertExists
%test:arg('role', 'scribe') %test:assertExists
function api:roleID($role as xs:string*, $ID as xs:string*) {

let $log := log:add-log-message('/api/hasrole/' || $role, xmldb:get-current-user(), 'REST')
let $path :=  collection($config:data-root)//t:persName[@role = $role][@ref=$ID]
let $hits := for $x in $path
                        let $root := string(root($x)/t:TEI/@xml:id)
                        group by $r := $root
                    return
                        map {
                            'prov' : $r,
                            'sourceTitle' : titles:printTitleID($r),
                            'count' := count($x)
                            }
                    
let $hs := if (count($hits) gt 1) then $hits else [$hits]
 return
             ( $api:response200Json,
            map {
                'pwl' : $ID,
                'title' : titles:printTitleMainID($ID),
                'hits' : count($path),
                'hasthisrole' : $hs    
                    }
)
};


(:~ builds XPath as string to be added to string which will be evaluated by API search. :)
declare function api:BuildSearchQuery($element as xs:string, $query as xs:string){
let $SearchOptions :=
    <options>
        <default-operator>or</default-operator>
        <phrase-slop>0</phrase-slop>
        <leading-wildcard>yes</leading-wildcard>
        <filter-rewrite>yes</filter-rewrite>
    </options>
    return
concat("descendant::t:", $element, "[ft:query(., '" , $query, "', ", serialize($SearchOptions) ,")]")
};


(:~ returns a map containing the KWIC hits from the evaluation of an xpath containing lucene full text index queries for the API search. :)
declare
%rest:GET
%rest:path("/BetMas/api/kwicsearch")
%rest:query-param("q", "{$q}", "")
%rest:query-param("element", "{$element}", "")
%output:method("json")
function api:kwicSearch($element as xs:string*, $q as xs:string*) {

let $log := log:add-log-message('/api/kwicsearch?q=' || $q, xmldb:get-current-user(), 'REST')
    let $login := xmldb:login('/db/apps/BetMas/data', $config:ADMIN, $config:ppw)
    
 let $hits :=  
 let $elements : =
     for $e in $element
    return 
    api:BuildSearchQuery($e, all:substitutionsInQuery($q))
let $allels := string-join($elements, ' or ')
let $eval-string := concat("collection('", $config:data-root, "')//t:TEI[",$allels, "]")

return
util:eval($eval-string)

let $hi :=   for $hit in $hits
                    let $expanded := kwic:expand($hit)
                    let $id := string($hit/@xml:id)
                    let $collection := switch($hit/@type) case 'mss' return 'manuscripts'case 'place' return 'places' case 'work' return 'works' case 'narr' return 'narratives' case 'ins' return 'institutions' case 'pers' return 'persons' default return 'authority-files'
                   let $ptest := titles:printTitleMainID($id)
                   let $title := if ($ptest) then ($ptest) else ()
                    let $count := count($expanded//exist:match)
                    let $results := kwic:summarize($hit,<config width="40"/>)
                   let $pname := $expanded//exist:match[ancestor::t:div[@type='edition']]
                   
                   let $text := if($pname) then 'text' else 'main'
                   
                   let $textpart := if($text = 'text') then 
                          let $tpart := $expanded//exist:match[ancestor::t:div[@type='edition']][1]/ancestor::t:div[@type='textpart'][1]/@n
                         
                          return if($tpart[1]) then  string($tpart[1]) else if ($tpart ='') then '1' else '1'
                          else ('1')
                          
                   return
                        map {
                            "id" := $id,
                            "text" := $text,
                            "textpart" := $textpart,
                            "collection" := $collection,
                            "title" := $title,
                            "hitsCount" := $count,
                            "results" := $results                        
                        }
let $c := count($hits)
return
    if (count($hits) gt 0) then
        ($api:response200Json,
       map {
            "items" := $hi,
            "total":= $c
        
        })
    else
        <json:value>
            <json:value
                json:array="true">
                <info>No results, sorry</info>
            </json:value>
        </json:value>
};



(:~ returns a json object containing the hits from the evaluation of an xpath containing lucene full text index queries for the API search. :)
declare
%rest:GET
%rest:path("/BetMas/api/search")
%rest:query-param("q", "{$q}", "")
%rest:query-param("element", "{$element}", "title")
%rest:query-param("collection", "{$collection}", "")
%rest:query-param("script", "{$script}", "")
%rest:query-param("material", "{$material}", "")
%rest:query-param("homophones", "{$homophones}", "true")
%rest:query-param("descendants", "{$descendants}", "true")
%output:method("json")
function api:search($element as xs:string+,
$q as xs:string*,
$collection as xs:string*,
$script as xs:string*,
$material as xs:string*,
$term as xs:string*,
$homophones as xs:string*,
$descendants as xs:string*) {

let $log := log:add-log-message('/api/search?q=' || $q, xmldb:get-current-user(), 'REST')
    let $login := xmldb:login('/db/apps/BetMas/data', $config:ADMIN, $config:ppw)
    let $SearchOptions :=
    <options>
        <default-operator>or</default-operator>
        <phrase-slop>0</phrase-slop>
        <leading-wildcard>yes</leading-wildcard>
        <filter-rewrite>yes</filter-rewrite>
    </options>
    let $script := if ($script != '') then
        ("[ancestor::t:TEI//@script = '" || $script || "' ]")
    else
        ''
    let $material := if ($material != '') then
        ("[ancestor::t:TEI//t:material/@key = '" || $material || "' ]")
    else
        ''
    let $term := if ($term != '') then
        ("[ancestor::t:TEI//t:term/@key = '" || $term || "' ]")
    else
        ''
    
    let $collection := switch ($collection)
        case 'manuscripts'
            return
                "[ancestor::t:TEI/@type = 'mss']"
        case 'works'
            return
                "[ancestor::t:TEI/@type = 'work']"
        case 'places'
            return
                "[ancestor::t:TEI/@type = 'place']"
        case 'institutions'
            return
                "[ancestor::t:TEI/@type = 'ins']"
        case 'narratives'
            return
                "[ancestor::t:TEI/@type = 'narr']"
        case 'authority-files'
            return
                "[ancestor::t:TEI/@type = 'auth']"
        case 'persons'
            return
                "[ancestor::t:TEI/@type = 'pers']"
        default return
            ''
let $query-string := if($homophones = 'true') then all:substitutionsInQuery($q) else ($q)
         
let $hits := 
for $e in $element 
let $eval-string := if($e = 'persName' and $descendants = 'false')  then
concat("collection('", $config:data-root, "')//t:person/t:persName"
, "[ft:query(.,'", $query-string, "',",serialize($SearchOptions),")]", $collection, $script, $material, $term)
else if($e = 'placeName'  and $descendants = 'false')  then
concat("collection('", $config:data-root, "')//t:place/t:placeName"
, "[ft:query(.,'", $query-string, "',",serialize($SearchOptions),")]", $collection, $script, $material, $term)
else concat("collection('", $config:data-root, "')//t:"
, $e, "[ft:query(.,'", $query-string, "',",serialize($SearchOptions),")]", $collection, $script, $material, $term)

return util:eval($eval-string)


let $results := 
                    for $hit in $hits
                    let $id := string($hit/ancestor::t:TEI/@xml:id)
                     let $t := normalize-space(titles:printTitleMainID($id))
               let $r := normalize-space(string-join($hit//text(), ' '))
                    return
                       map{
            'id': $id,
            'title' : $t,
            'result' : $r
            }
              
let $c := count($hits)
return
    if (count($hits) gt 0) then
        ($api:response200Json,
        map {
            'items' : $results,
           'total' : $c
        })
    else
        <json:value>
            <json:value
                json:array="true">
                <info>No results, sorry</info>
            </json:value>
        </json:value>
};




(:~ returns a json object with an array of object one for each resource in the specified collection :)
declare
%rest:GET
%rest:path("/BetMas/api/{$collection}/list/json")
%rest:query-param("start", "{$start}", 1)
%rest:query-param("perpage", "{$perpage}", 25)
%rest:query-param("term", "{$term}", "")
%rest:query-param("repo", "{$repo}", "")
%output:method("json")
function api:collectionJSON($collection as xs:string*, $start as xs:integer*, $perpage as xs:integer*, $term as xs:string*, $repo as xs:string*) {
    
let $log := log:add-log-message('/api/'||$collection||'/list/json', xmldb:get-current-user(), 'REST')
    (: logs into the collection :)
    let $login := xmldb:login('/db/apps/BetMas/data', $config:ADMIN, $config:ppw)
    return
         ( $api:response200Json,
    
    let $term := if ($term != '') then
        ("[descendant::t:term/@key = '" || $term || "' ]")
    else
        ''
          let $repo := if ($repo != '') then
        ("[descendant::t:repository/@ref = '" || $repo || "' ]")
    else
        ''
    let $collecPath := switch ($collection)
        case 'works'
            return
                $config:data-rootW
        case 'persons'
            return
                $config:data-rootPr
        case 'institutions'
            return
                $config:data-rootIn
        case 'manuscripts'
            return
                $config:data-rootMS
        case 'narratives'
            return
                $config:data-rootN
        case 'authority-files'
            return
                $config:data-rootA
        case 'places'
            return
                $config:data-rootPl
        default return
            $config:data-root

let $path := concat("collection('",
$collecPath
, "')//t:TEI", $repo, $term)

let $hits := util:eval($path)

return
    <json:value>
        <items>
            {
                for $resource in subsequence($hits, $start, $perpage)
                let $rid := $resource/@xml:id
                let $rids := string($rid)
                let $title := titles:printTitleMainID($rid)
                order by $title[1] descending
                return
                    <json:value
                        json:array="true">
                        <id>{$rids}</id>
                        <title>{$title}</title>
                        {
                        element item {
                                element uri {base-uri($resource)},
                                element name {util:unescape-uri(replace(base-uri($resource), ".+/(.+)$", "$1"), "UTF-8")},
                                element type {string($resource/@type)},
                                switch ($resource/@type)
                                    case 'mss'
                                        return
                                            (
                                            element support {
                                                for $r in $resource//@form
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element institution {
                                                for $r in $resource//t:repository/@ref
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            },
                                            element script {
                                                for $r in $resource//@script
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element material {
                                                for $r in $resource//t:support/t:material/@key
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element keyword {
                                                for $r in $resource//t:term/@key
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element language {
                                                for $r in $resource//t:language
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element content {
                                                for $r in $resource//t:title/@ref
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element scribe {
                                                for $r in $resource//t:persName[@role = 'scribe']/@ref[not(. = 'PRS00000') and not(. = 'PRS0000')]
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            },
                                            element donor {
                                                for $r in $resource//t:persName[@role = 'donor']/@ref[not(. = 'PRS00000') and not(. = 'PRS0000')]
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            },
                                            element patron {
                                                for $r in $resource//t:persName[@role = 'patron']/@ref[not(. = 'PRS00000') and not(. = 'PRS0000')]
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            })
                                    case 'pers'
                                        return
                                            (element occupation {
                                                for $r in $resource//t:occupation
                                                return
                                                    replace(normalize-space($r), ' ', '_') || ' '
                                            },
                                            element role {
                                                for $r in $resource//t:person/t:persName/t:roleName
                                                return
                                                    replace(normalize-space($r), ' ', '_') || ' '
                                            },
                                            element gender {$resource//t:person/@sex})
                                    case 'place'
                                        return
                                            (element placeType {
                                                for $r in $resource//t:place/@type
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            },
                                            element tabot {
                                                for $r in $resource//t:ab[@type = 'tabot']/t:persName/@ref
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            })
                                    
                                    case 'ins'
                                        return
                                            (element placeType {
                                                for $r in $resource//t:place/@type
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            },
                                            element tabot {
                                                for $r in $resource//t:ab[@type = 'tabot']/t:persName/@ref
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            })
                                    case 'work'
                                        return
                                            (element keyword {
                                                for $r in $resource//t:term/@key
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element language {
                                                for $r in $resource//t:language
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element author {
                                                for $r in ($resource//t:relation[@name = "saws:isAttributedToAuthor"]/@passive, $resource//t:relation[@name = "dcterms:creator"]/@passive)
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            },
                                            element witness {
                                                for $r in $resource//t:witness/@corresp
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            })
                                    case 'narr'
                                        return
                                            (element keyword {
                                                for $r in $resource//t:term/@key
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element language {
                                                for $r in $resource//t:language
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element author {
                                                for $r in ($resource//t:relation[@name = "saws:isAttributedToAuthor"]/@passive, $resource//t:relation[@name = "dcterms:creator"]/@passive)
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            })
                                    default return
                                        ()
                        }
                    }
                </json:value>
        }
    
    </items>
    <total>{count($hits)}</total>
</json:value>)
};

(:~ returns a json object with an array of object one for each resource in the specified repository with id and title :)
declare
%rest:GET
%rest:path("/BetMas/api/manuscripts/{$repo}/list/ids/json")
%output:method("json")
function api:listRepoJSON($repo as xs:string*) {
    
let $log := log:add-log-message('/api/manuscripts/'||$repo||'/list/ids/json', xmldb:get-current-user(), 'REST')
    (: logs into the collection :)
    let $login := xmldb:login('/db/apps/BetMas/data', $config:ADMIN, $config:ppw)
    return
         ( $api:response200Json,
    let $msfromrepo := collection($config:data-rootMS)//t:TEI[descendant::t:repository[@ref = $repo]]
    let $total := count($msfromrepo) 
   let $items :=  for $resource in $msfromrepo 
    let $id := string($resource/@xml:id)
    let $title :=  titles:printTitleMainID($id)
    return map {'id' := $id, 'title' := $title}
    return 
    map {'items' := $items,
    'total' := $total}
    )
};

(:~ returns a json object with an array of object one for each resource in the specified collection :)
declare
%rest:GET
%rest:path("/BetMas/api/{$collection}/list")
%rest:query-param("start", "{$start}", 1)
%rest:query-param("perpage", "{$perpage}", 25)
%rest:query-param("term", "{$term}", "")
%output:method("xml")
%test:args('manuscripts', '1', '20', 'GoldenGospel') %test:assertXPath('/','item')
function api:collection($collection as xs:string*, $start as xs:integer*, $perpage as xs:integer*, $term as xs:string*) {
    if ($perpage gt 100) then ($api:response200XML, <info>Try a lower value for the parameter perpage. Maximum is 100.</info>) else
let $log := log:add-log-message('/api/' || $collection || '/list', xmldb:get-current-user(), 'REST')
    (: logs into the collection :)
    let $login := xmldb:login('/db/apps/BetMas/data', $config:ADMIN, $config:ppw)
    return
        ( $api:response200XML,
    
    let $term := if ($term != '') then
        ("[descendant::t:term/@key = '" || $term || "' ]")
    else
        ''
    let $collecPath := switch ($collection)
        case 'works'
            return
                $config:data-rootW
        case 'persons'
            return
                $config:data-rootPr
        case 'personsNoEthnic'
            return
                $config:data-rootPr
        case 'institutions'
            return
                $config:data-rootIn
        case 'manuscripts'
            return
                $config:data-rootMS
        case 'narratives'
            return
                $config:data-rootN
        case 'authority-files'
            return
                $config:data-rootA
        case 'places'
            return
                $config:data-rootPl
        default return
            $config:data-root

let $path := concat("collection('",
$collecPath
, "')//t:TEI", if($collection='personsNoEthnic') then "[starts-with(@xml:id, 'PRS')]" else (), $term)

let $hits := util:eval($path)

return
    
    
    <items>
        {
            for $resource in subsequence($hits, $start, $perpage)
            let $title := titles:printTitleMainID(string($resource/@xml:id))
            order by $title[1] descending
            return
                
                element item {
                    attribute uri {base-uri($resource)},
                    attribute name {util:unescape-uri(replace(base-uri($resource), ".+/(.+)$", "$1"), "UTF-8")},
                    attribute id {string($resource/@xml:id)},
                    attribute type {string($resource/@type)},
                    switch ($resource/@type)
                        case 'mss'
                            return
                                (
                                attribute support {
                                    for $r in $resource//@form
                                    return
                                        string($r) || ' '
                                },
                                attribute institution {
                                    for $r in $resource//t:repository/@ref
                                    return
                                        string($r) || ' '
                                },
                                attribute script {
                                    for $r in $resource//@script
                                    return
                                        string($r) || ' '
                                },
                                attribute material {
                                    for $r in $resource//t:support/t:material/@key
                                    return
                                        string($r) || ' '
                                },
                                attribute keyword {
                                    for $r in $resource//t:term/@key
                                    return
                                        string($r) || ' '
                                },
                                attribute language {
                                    for $r in $resource//t:language
                                    return
                                        string($r) || ' '
                                },
                                attribute content {
                                    for $r in $resource//t:title/@ref
                                    return
                                        string($r) || ' '
                                },
                                attribute scribe {
                                    for $r in $resource//t:persName[@role = 'scribe']/@ref[not(. = 'PRS00000') and not(. = 'PRS0000')]
                                    return
                                        string($r) || ' '
                                },
                                attribute donor {
                                    for $r in $resource//t:persName[@role = 'donor']/@ref[not(. = 'PRS00000') and not(. = 'PRS0000')]
                                    return
                                        string($r) || ' '
                                },
                                attribute patron {
                                    for $r in $resource//t:persName[@role = 'patron']/@ref[not(. = 'PRS00000') and not(. = 'PRS0000')]
                                    return
                                        string($r) || ' '
                                })
                        case 'pers'
                            return
                                (attribute occupation {
                                    for $r in $resource//t:occupation
                                    return
                                        replace(normalize-space($r), ' ', '_') || ' '
                                },
                                attribute role {
                                    for $r in $resource//t:person/t:persName/t:roleName
                                    return
                                        replace(normalize-space($r), ' ', '_') || ' '
                                },
                                attribute gender {$resource//t:person/@sex})
                        case 'place'
                            return
                                (attribute placeType {
                                    for $r in $resource//t:place/@type
                                    return
                                        string($r) || ' '
                                },
                                attribute tabot {
                                    for $r in $resource//t:ab[@type = 'tabot']/t:persName/@ref
                                    return
                                        string($r) || ' '
                                })
                        case 'ins'
                            return
                                (attribute placeType {
                                    for $r in $resource//t:place/@type
                                    return
                                        string($r) || ' '
                                },
                                attribute tabot {
                                    for $r in $resource//t:ab[@type = 'tabot']/t:persName/@ref
                                    return
                                        string($r) || ' '
                                })
                        case 'work'
                            return
                                (attribute keyword {
                                    for $r in $resource//t:term/@key
                                    return
                                        string($r) || ' '
                                },
                                attribute language {
                                    for $r in $resource//t:language
                                    return
                                        string($r) || ' '
                                },
                                attribute author {
                                    for $r in ($resource//t:relation[@name = "saws:isAttributedToAuthor"]/@passive, $resource//t:relation[@name = "dcterms:creator"]/@passive)
                                    return
                                        string($r) || ' '
                                },
                                attribute witness {
                                    for $r in $resource//t:witness/@corresp
                                    return
                                        string($r) || ' '
                                })
                        case 'narr'
                            return
                                (attribute keyword {
                                    for $r in $resource//t:term/@key
                                    return
                                        string($r) || ' '
                                },
                                attribute language {
                                    for $r in $resource//t:language
                                    return
                                        string($r) || ' '
                                },
                                attribute author {
                                    for $r in ($resource//t:relation[@name = "saws:isAttributedToAuthor"]/@passive, $resource//t:relation[@name = "dcterms:creator"]/@passive)
                                    return
                                        string($r) || ' '
                                })
                        default return
                            (),
                $title
            }
    }
    <total>{count($hits)}</total>
</items>)

};


(:~ returns a xml fragment with the element in a resource which has the given anchor:)
declare
%rest:GET
%rest:path("/BetMas/api/otherMssText/{$id}/{$SUBid}")
%rest:query-param("element", "{$element}", "")
%output:method("xml")
%test:args('IVefiopsk1', 'a1', 'item') %test:assertXPath('//element')
function api:get-othertext($id as xs:string, $SUBid as xs:string, $element as xs:string*) {

let $log := log:add-log-message('/api/otherMssText/' || $id || '/' || $SUBid, xmldb:get-current-user(), 'REST')  
  let $login := xmldb:login('/db/apps/BetMas/data', $config:ADMIN, $config:ppw)
    return
        
         ( $api:response200XML,
        let $collection := 'manuscripts'
        let $item := api:get-tei-rec-by-ID($id)
        return
            if ($item//t:*[(name() = $element) or (@xml:id = $SUBid)]//text())
            then
                let $match := $item//t:*[@xml:id = $SUBid]//name()
                return
                    <othermsselement>
                        <id>{$id}</id>
                        <element>{$match} #{$SUBid}</element>
                        <url>{$config:appUrl}/manuscripts/{$id}#{$SUBid}</url>
                        {
                            for $q in $item//t:*[@xml:id = $SUBid]/t:q
                            return
                                <text
                                    lang="{$q/@xml:lang}">{$q/text()}</text>
                        }
                        
                        {
                            
                            for $type in $item//t:*[@xml:id = $SUBid]/t:*[@type]
                            return
                                <type>{string($type/@type)}</type>
                        }
                        {
                            if ($match = 'msPart') then
                                <contains>
                                    {
                                        for $e in $item//t:*[@xml:id = $SUBid]//child::*
                                        return
                                            element {$e/name()} {$e/text()}
                                    }
                                </contains>
                            else
                                if ($match = 'msItem') then
                                    (<is>{string($item//t:*[@xml:id = $SUBid]/t:title/@corresp)}</is>,
                                    <contains>
                                        {
                                            for $e in $item//t:*[@xml:id = $SUBid]//child::*
                                            return
                                                element {$e/name()} {$e/text()}
                                        }</contains>)
                                
                                else
                                    ()
                        }
                    </othermsselement>
            else
                let $call := $config:appUrl || '/api/extra/' || $id || '/' || $SUBid
                return
                    api:noresults($call)
        )
};

(:~
 : The following function retrive the text of the selected work and returns
: it with basic informations for next and following into a small XML tree

:)
declare
%rest:GET
%rest:path("/BetMas/api/xml/{$id}")
%output:method("xml")
%test:arg('id', 'LIT1367Exodus') %test:assertXPath('//contains')
function api:get-workXML($id as xs:string) {

    let $log := log:add-log-message('/api/xml/' || $id, xmldb:get-current-user(), 'REST')
    let $login := xmldb:login('/db/apps/BetMas/data', $config:ADMIN, $config:ppw)
    return
        
        ($api:response200XML,
        let $collection := 'works'
        let $item := api:get-tei-rec-by-ID($id)
        let $recordid := $item/t:TEI/@xml:id
        return
            if ($item//t:div[@type = 'edition'])
            then
                <work>
                    <id>{data($recordid)}</id>
                    <text>{$item//t:div[@type = 'edition']//text()}</text>
                    <contains>
                        {
                            for $subtype in $item//t:div[@type = 'edition']/t:div[@subtype]
                            return
                                
                                element {string($subtype/@subtype)} {($config:appUrl || '/api/xml/' || $id || '/' || $subtype/@n)}
                        }
                    </contains>
                
                
                </work>
            
            else
                let $call := $config:appUrl || '/api/xml/' || $id
                return
                    api:noresults($call)
        )
};

declare function api:citation($item as node()){
if($item//t:titleStmt/t:title[@type='short']) then $item//t:titleStmt/t:title[@type='short']/text() else $item//t:titleStmt/t:title[@xml:id = 't1']/text()};



(: ~ returns the full first level subdivision

e.g. Ex. 1 

:)
declare
%rest:GET
%rest:path("/BetMas/api/xml/{$id}/{$level1}")
%output:method("xml")
%test:args('LIT1367Exodus', '1') %test:assertXPath('//partofwork')
function api:get-level1XML($id as xs:string, $level1 as xs:string*) {
    ($api:response200XML,
    
    let $log := log:add-log-message('/api/xml/' || $id || '/' || $level1, xmldb:get-current-user(), 'REST')
    let $collection := 'works'
    let $item := api:get-tei-rec-by-ID($id)
    let $recordid := $item/@xml:id
    
    return
        if ($item//t:div[@type = 'edition']/t:div[@n = $level1][t:ab])
        then
            <work>
                
                <id>{data($recordid)}</id>
                <citation>{(api:citation($item) || ' ' || $level1)}</citation>
                <title>{$item//t:titleStmt/t:title[@xml:id = 't1']/text()}</title>
                <text>{$item//t:div[@type = 'edition']/t:div[@n = $level1]//text()}</text>
                
                {
                    if (number($level1) > 1)
                    then
                        <previous>{$config:appUrl}/api/xml/{$id}/{number($level1) - 1}</previous>
                    else
                        ()
                }
                
                {
                    if (number($level1) = count($item//t:div[@type = 'edition']/t:div))
                    then
                        ()
                    else
                        if ($item//t:div[@type = 'edition']/t:div[@n = (number($level1) + 1)])
                        then
                            <next>{$config:appUrl}/api/xml/{$id}/{number($level1) + 1}</next>
                        else
                            ()
                }
                
                <partofwork>{$config:appUrl}/api/xml/{$id}</partofwork>
                <contains>
                    {
                        for $subtype in $item//t:div[@type = 'edition']/t:div[@subtype]
                        return
                            
                            element {string($subtype/@subtype)} {($config:appUrl || '/api/xml/' || $id || '/' || $subtype/@n)}
                    }
                </contains>
            </work>
        else
            let $call := $config:appUrl || '/api/xml/' || $id || '/' || $level1
            return
                api:noresults($call)
    )
};


(:~ returns the lines of the first level subdivision

Ex. 2,4

Ex. 2, 4-7

:)
declare
%rest:GET
%rest:path("/BetMas/api/xml/{$id}/{$level1}/{$line}")
%output:method("xml")
%test:args('LIT1367Exodus', '1','1-2') %test:assertXPath('//partOf')
function api:get-level1LineXML($id as xs:string, $level1 as xs:string*, $line as xs:string*) {
    ($api:response200XML,
    
    let $log := log:add-log-message('/api/xml/' || $id || '/' || $level1 || '/' || $line, xmldb:get-current-user(), 'REST')
    let $collection := 'works'
    let $item := api:get-tei-rec-by-ID($id)
    
    let $recordid := $item/@xml:id
    let $L1 := $item//t:div[@type = 'edition']/t:div[@n = $level1]
    return
        if (contains($line, '-'))
        then
            <work>
                <id>{data($recordid)}</id>
                <citation>{(api:citation($item) || ' ' || $level1 || ', ' || $line)}</citation>
                <title>{$item//t:titleStmt/t:title[@xml:id = 't1']/text()}</title>
                <text>{
                        for $l in (xs:integer(substring-before($line, '-')) to xs:integer(substring-after($line, '-')))
                        let $textnodes := $L1//t:l[@n = string($l)]
                        let $onlytext := string-join($textnodes//text(), '')
                        return
                            normalize-space($onlytext)
                    }</text>
                {
                    if (number(substring-before($line, '-')) > 1)
                    then
                        <previous>{$config:appUrl}/api/xml/{$id}/{$level1}/{number(substring-before($line, '-')) - 1}</previous>
                    else
                        ()
                }
                {
                    if (number($line) = count($L1//t:l[@n = substring-after($line, '-')]))
                    then
                        ()
                    else
                        if ($L1//t:l[@n = (number(substring-after($line, '-')) + 1)])
                        then
                            <next>{$config:appUrl}/api/xml/{$id}/{$level1}/{number(substring-after($line, '-')) + 1}</next>
                        else
                            ()
                }<partOf>
                    {element {string($L1/@subtype)} {$config:appUrl || '/api/xml/' || $id || '/' || $level1}}
                    
                    {element {'work'} {$config:appUrl || '/api/xml/' || $id}}
                
                </partOf>
                <contains>
                    {
                        for $subtype in $L1/t:div[@subtype]
                        return
                            
                            element {string($subtype/@subtype)} {($config:appUrl || '/api/xml/' || $id || '/' || $subtype/@n)}
                    }
                </contains>
            </work>
        else
            if ($L1//t:l[@n = $line])
            then
                <work>
                    
                    <id>{data($recordid)}</id>
                    <citation>{(api:citation($item) || ' ' || $level1 || ', ' || $line)}</citation>
                    <title>{$item//t:titleStmt/t:title[@xml:id = 't1']/text()}</title>
                    
                    <text>{
                    let $textnodes := $L1//t:l[@n = $line]//text()
                        let $onlytext := string-join($textnodes, '')
                        return
                            normalize-space($onlytext)}</text>
                    {
                        if (number($line) > 1)
                        then
                            <previous>{$config:appUrl}/api/xml/{$id}/{$level1}/{number($line) - 1}</previous>
                        else
                            ()
                    }
                    {
                        if (number($line) = count($L1//t:l[@n = $line]))
                        then
                            ()
                        else
                            if ($L1//t:l[@n = (number($line) + 1)])
                            then
                                <next>{$config:appUrl}/api/xml/{$id}/{$level1}/{number($line) + 1}</next>
                            else
                                ()
                    }<partOf>
                        {element {string($L1/@subtype)} {$config:appUrl || '/api/xml/' || $id || '/' || $level1}}
                        
                        {element {'work'} {$config:appUrl || '/api/xml/' || $id}}
                    
                    </partOf>
                    <contains>
                        {
                            for $subtype in $L1/t:div[@subtype]
                            return
                                
                                element {string($subtype/@subtype)} {($config:appUrl || '/api/xml/' || $id || '/' || $subtype/@n)}
                        }
                    </contains>
                </work>
            else
                let $call := $config:appUrl || '/api/xml/' || $id || '/' || $level1 || '/' || $line
                return
                    api:noresults($call)
    )
};




(:~ returns the lines of the second level of subdivision (subchapters)

XXX. 1 2,4

XXX. 1 2, 4-7

:)


declare
%rest:GET
%rest:path("/BetMas/api/xml/{$id}/{$level1}/{$level2}/{$line}")
%output:method("xml")
%test:args('LIT1367Exodus', '1','1','1-2') %test:assertXPath('//partOf')
function api:get-level2lineXML($id as xs:string, $level1 as xs:string*, $level2 as xs:string*, $line as xs:string*) {
    ($api:response200XML,
      let $log := log:add-log-message('/api/xml/' || $id || '/' || $level1|| '/' || $level2 || '/' || $line, xmldb:get-current-user(), 'REST')
  
    let $collection := 'works'
    let $item := api:get-tei-rec-by-ID($id)
    let $recordid := $item/@xml:id
    let $L1 := $item//t:div[@type = 'edition']/t:div[@n = $level1]
    let $L2 := $L1/t:div[@n = $level2]
    
    return
        if (contains($line, '-'))
        then
            <work>
                <id>{data($recordid)}</id>
                <citation>{(api:citation($item) || ' ' || $level2 || ', ' || $line)}</citation>
                <title>{$item//t:titleStmt/t:title[@xml:id = 't1']/text()}</title>
                <text>{
                        for $l in (xs:integer(substring-before($line, '-')) to xs:integer(substring-after($line, '-')))
                        let $textnodes := $L2//t:l[@n = string($l)]
                        let $onlytext := string-join($textnodes//text(), '')
                        return
                            normalize-space($onlytext)
                    }</text>
                {
                    if (number(substring-before($line, '-')) > 1)
                    then
                        <previous>{$config:appUrl}/api/xml/{$id}/{$level1}/{$level2}/{number(substring-before($line, '-')) - 1}</previous>
                    else
                        ()
                }
                {
                    if (number($line) = count($L2//t:l[@n = substring-after($line, '-')]))
                    then
                        ()
                    else
                        if ($L2//t:l[@n = (number(substring-after($line, '-')) + 1)])
                        then
                            <next>{$config:appUrl}/api/xml/{$id}/{$level1}/{$level2}/{number(substring-after($line, '-')) + 1}</next>
                        else
                            ()
                }<partOf>
                    
                    {element {string($L2/@subtype)} {$config:appUrl || '/api/xml/' || $id || '/' || $level1 || '/' || $level2}}
                    {element {string($L1/@subtype)} {$config:appUrl || '/api/xml/' || $id || '/' || $level1}}
                    
                    {element {'work'} {$config:appUrl || '/api/xml/' || $id}}
                
                </partOf>
                <contains>
                    {
                        for $subtype in $L2/t:div[@subtype]
                        return
                            
                            element {string($subtype/@subtype)} {($config:appUrl || '/api/xml/' || $id || '/' || $subtype/@n)}
                    }
                </contains>
            
            </work>
        else
            if ($item//t:div[@type = 'edition']/t:div[@n = $level1]/t:div[@n = $level2]//t:*[@n = $line])
            then
                <work>
                    
                    <id>{data($recordid)}</id>
                    <citation>{(api:citation($item) || ' ' || $level1 || ' ' || $level2 || ', ' || $line)}</citation>
                    <title>{$item//t:titleStmt/t:title[@xml:id = 't1']/text()}</title>
                    
                    <text>{ let $textnodes := $L2//t:l[@n = $line]//text()
                        let $onlytext := string-join($textnodes, '')
                        return
                            normalize-space($onlytext)}</text>
                    {
                        if (number($line) > 1)
                        then
                            <previous>{$config:appUrl}/api/xml/{$id}/{$level1}/{$level2}/{number($line) - 1}</previous>
                        else
                            ()
                    }
                    {
                        if (number($line) = count($L2//t:l[@n = $line]))
                        then
                            ()
                        else
                            if ($L2//t:l[@n = (number($line) + 1)])
                            then
                                <next>{$config:appUrl}/api/xml/{$id}/{$level1}/{$level2}/{number($line) + 1}</next>
                            else
                                ()
                    }<partOf>
                        
                        {element {string($L2/@subtype)} {$config:appUrl || '/api/xml/' || $id || '/' || $level1 || '/' || $level2}}
                        {element {string($L1/@subtype)} {$config:appUrl || '/api/xml/' || $id || '/' || $level1}}
                        
                        {element {'work'} {$config:appUrl || '/api/xml/' || $id}}
                    
                    </partOf>
                    <contains>
                        {
                            for $subtype in $L2/t:div[@subtype]
                            return
                                
                                element {string($subtype/@subtype)} {($config:appUrl || '/api/xml/' || $id || '/' || $subtype/@n)}
                        }
                    </contains>
                
                </work>
            else
                let $call := $config:appUrl || '/api/xml/' || $id || '/' || $level1 || '/' || $level2 || '/' || $line
                return
                    api:noresults($call)
    )
};

(:~ given the file id, returns the source TEI xml:)
declare
%rest:GET
%rest:path("/BetMas/api/{$id}/tei")
%output:media-type("text/xml")
%output:method("xml")
%test:arg('id','LIT1367Exodus') %test:assertXPath("//t:text")
function api:get-tei-by-ID($id as xs:string) {
    let $log := log:add-log-message('/api/' || $id || '/tei', xmldb:get-current-user(), 'REST')
    let $login := xmldb:login('/db/apps/BetMas/data', 'Pietro', 'Hdt7.10')
    return
        ($api:response200XML,
        api:get-tei-rec-by-ID($id)
        )
};

(:~ given the file id, returns the source TEI in a json serialization:)
declare
%rest:GET
%rest:path("/BetMas/api/{$id}/json")
%output:method("json")
function api:get-tei2json-by-ID($id as xs:string) {
    
    let $log := log:add-log-message('/api/' || $id || '/json', xmldb:get-current-user(), 'REST')
    let $login := xmldb:login('/db/apps/BetMas/data', 'Pietro', 'Hdt7.10')
    return
        ($api:response200Json,
        <json:value>{api:get-tei-rec-by-ID($id)}</json:value>
        )
};


(:~ given the file id, returns the main title:)
declare
%rest:GET
%rest:path("/BetMas/api/{$id}/title")
%output:method("text")
%test:arg('id','LIT1367Exodus') %test:assertEquals('<rest:response><http:response status="200"><http:header name="Access-Control-Allow-Origin" value="*" /></http:response></rest:response>',"Exodus")
function api:get-FormattedTitle($id as xs:string) {
    ($api:response200,
   normalize-space(titles:printTitleMainID($id))
    
    )
};


(:~ given the file id and an anchor, returns the formatted main title and the title of the reffered section:)
declare
%rest:GET
%rest:path("/BetMas/api/{$id}/{$SUBid}/title")
%output:method("text")
%test:args('BNFet32','a1') %test:assertEquals('<rest:response><http:response status="200"><http:header name="Access-Control-Allow-Origin" value="*" /></http:response></rest:response>',"Paris, Bibliothèque nationale de France, Éthiopien 32, Scribal Note Completing a1")
function api:get-FormattedTitleandID($id as xs:string, $SUBid as xs:string) {
    ($api:response200, 
    let $resource := api:get-tei-rec-by-ID($id)
    let $m := titles:printTitleMainID($id) 
    return
    if( starts-with($SUBid, 'tr')) then $m || ', transformation ' ||  $SUBid
else if( starts-with($SUBid, 'Uni')) then $m ||', '||$SUBid 
else
    (:    if pointing to a specific label, print that:)
    if (starts-with($SUBid, 't'))
    then
        (
        let $subtitlemain := $resource//t:title[contains(@corresp, $SUBid)][@type = 'main']
        let $subtitlenorm := $resource//t:title[contains(@corresp, $SUBid)][@type = 'normalized']
        return
            if ($subtitlemain)
            then
                $subtitlemain
            else
                if ($subtitlenorm)
                then
                    $subtitlenorm
                else
                    let $tit := $resource//t:title[@xml:id = $SUBid]
                    return $tit/text()
                    )
    else
    let $s := titles:printSubtitle($resource, $SUBid)
    return
        (:    apply general rules for titles of records:)
        ($m, ', ', $s)
    )
};



(:~
 : Returns tei record
:)
declare function api:get-tei-rec($collection as xs:string, $id as xs:string) as node()* {
    let $uri := concat($config:data-root, '/', $collection, '/', $id, '.xml')
    return
        doc($uri)
};

declare function api:get-tei-rec-by-ID($id as xs:string) as node()* {
    collection($config:data-root)//id($id)
};



(:~ this is the feedback in case no result is found:)
declare function api:noresults($call) {
    <html
        xmlns="http://www.w3.org/1999/xhtml">
        <head></head>
        <body>
            <h1>No results for {$call}, sorry!</h1>
            <br/>
            <p>Trouble shooting:
                <ul>
                    <li>The api documentation is <a
                            href="/apidoc.html">here.</a></li>
                    <li>Check the correct id exists <a
                            href="/works/list">here.</a></li>
                    <li>Your requested uri should look something like this
                        <blockquote>{$config:appUrl}/api/xml/{{id}}/{{level}}/{{level2}}/{{line}}</blockquote>
                        <blockquote>{$config:appUrl}/api/xml/LIT1367Exodus/2/4</blockquote>
                        <blockquote>{$config:appUrl}/api/xml/LIT1367Exodus/2/4-7</blockquote>
                        if not, see above! The first example will not work, the second and third will.
                        Why: if you ask for an extra level of structure which we don't have, you will not get results.</li>
                </ul>
            </p>
        </body>
    </html>
};

(:~
  : Atom feed (only general) adapted from syriaca.org code
:)
declare 
    %rest:GET
    %rest:path("/BetMas/api/atom")
    %rest:query-param("start", "{$start}", 1)
    %rest:query-param("perpage", "{$perpage}", 25)
    %output:media-type("application/atom+xml")
    %output:method("xml")
function api:get-atom-feed($start as xs:integer*, $perpage as xs:integer*){
   ($api:response200XML, 
   
    let $feed := collection($config:data-root)//t:TEI
   let $changes:= $feed//t:change[@when]
let $latests := 
    for $alllatest in $changes
    order by xs:date($alllatest/@when) descending
    return $alllatest


    let $total := count($feed)
    return 
     <feed  xmlns="http://www.w3.org/2005/Atom">
<title>betmasaheft.eu: {$total} resources </title>
<link href="{$config:appUrl}"/>
<link rel="self" type="application/atom+xml" href="{$config:appUrl}/api/atom"/>
<link rel="next" href="{concat($config:appUrl,'/api/atom?start=',$start + $perpage)}"/>
<link rel="last" href="{concat($config:appUrl,'/api/atom?start=',$total + $perpage)}"/>
<updated>{string($latests[1]/@when)}</updated>
<author>
<name>{$config:appUrl}</name>
</author>
{
for $latest at $count in subsequence($latests, $start, $perpage)
let $id := string(root($latest)/t:TEI/@xml:id)
let $type := string(root($latest)/t:TEI/@type)
let $collection:= api:switchcol($type)
return
<entry xmlns="http://www.w3.org/2005/Atom">
<title>{titles:printTitleMainID($id)}
</title>
<link rel="self" type="application/atom+xml" href="/api/{$id}/atom"/>
<link rel="alternate" type="text/xml" href="/api/{$id}/tei"/>
<link rel="alternate" type="text/json" href="/api/{$id}/json"/>
<link rel="alternate" type="html" href="/{$collection}/{$id}/main"/>
<link rel="alternate" type="html" href="/{$collection}/{$id}/analytic"/>
<link rel="alternate" type="html" href="/{$collection}/{$id}/text"/>
<link rel="alternate" type="application/rdf+xml" href="/{$id}.rdf"/>
<link rel="alternate" type="pdf" href="/{$id}.pdf"/>
<id>
{$config:appUrl}/{$id}
</id>
<updated>{string($latest/@when)}</updated>
</entry>}
</feed>
     )
};
