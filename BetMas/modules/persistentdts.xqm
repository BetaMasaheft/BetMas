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
import module namespace kwic = "http://exist-db.org/xquery/kwic"   at "resource:org/exist/xquery/lib/kwic.xql";
import module namespace app="https://www.betamasaheft.uni-hamburg.de/BetMas/app" at "xmldb:exist:///db/apps/BetMas/modules/app.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace sparql="http://exist-db.org/xquery/sparql" at "java:org.exist.xquery.modules.rdf.SparqlModule";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMas/string" at "xmldb:exist:///db/apps/BetMas/modules/tei2string.xqm";
import module namespace editors = "https://www.betamasaheft.uni-hamburg.de/BetMas/editors" at "xmldb:exist:///db/apps/BetMas/modules/editors.xqm";
import module namespace dts="https://www.betamasaheft.uni-hamburg.de/BetMas/dts" at "xmldb:exist:///db/apps/BetMas/modules/dts.xqm";

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
  "@context":= "/dts/api/contexts/EntryPoint.jsonld",
  "@id":= "/api/dts/",
  "@type":= "EntryPoint",
  "documents":= $doc,
  "navigation" := $nav
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
    <http:header name="location" value="/api/dts/collections?id=urn:dts"/>
  </http:response>
</rest:response>
) else
if(matches($id, '(urn:dts:?)(betmasMS:|betmas:)?([a-zA-Z\d]+)?(:)?(((\d+)(\w)?(\w)?((@)([\p{L}]+)(\[(\d+|last)\])?)?)?(\-)?((\d+)(\w)?(\w)?((@)([\p{L}]+)(\[(\d+|last)\])?)?)?)')) 
then (
let $parsedURN := dts:parseDTS($id)
return
if (matches($parsedURN//s:group[@nr=3], '[a-zA-Z\d]+'))
then (
                let $specificID := $parsedURN//s:group[@nr=3]/text() 
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
    <http:header name="location" value="/api/dts/collections?id=urn:dts"/>
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
 if(count($parsedURN//s:group[@nr=5]//text()) ge 1) then 
 let $location := if($parsedURN//s:group[@nr=15]/text() = '-') 
                    then ('permanent/'||$sha||'/api/dts/document?id='||$parsedURN//s:group[@nr=1]//text()||$parsedURN//s:group[@nr=2]//text()||$parsedURN//s:group[@nr=3]//text()|| '&amp;start=' ||$parsedURN//s:group[@nr=6]//text()|| '&amp;end=' ||$parsedURN//s:group[@nr=16]//text()) 
                    else ('permanent/'||$sha||'/api/dts/document?id='||$parsedURN//s:group[@nr=1]//text()||$parsedURN//s:group[@nr=2]//text()||$parsedURN//s:group[@nr=3]//text()|| '&amp;ref=' ||$parsedURN//s:group[@nr=5]//text())
 return
 <rest:response>
  <http:response status="302">
    <http:header name="location" value="{ $location }"/>
  </http:response>
</rest:response>
 else
 let $thisid := $parsedURN//s:group[@nr=3]/text()
 let $collection := if(contains($id, 'betmasMS')) then 'Manuscripts' else 'Works'
let $permapath := replace(persdts:capitalize-first(substring-after(base-uri($config:collection-root/id($id)[name()='TEI']), '/db/apps/BetMasData/')), $collection, '')
let $file:= doc('https://raw.githubusercontent.com/BetaMasaheft/' || $collection || '/'||$sha||'/'|| $permapath)//t:TEI
 let $text := $file//t:div[@type='edition']
 let $doc := 
(: in case there is passage, then look for that place:)
  if ($ref != '') then 
   if (contains($id,'betmasMS'))  
        then 
                        let $pass:= dts:parsePassageMS($ref)
                        let $level1 := $pass//s:group[@nr=1] 
                        let $level2 := if($pass//s:group[@nr=4]) then $pass//s:group[@nr=4] else ''
                        let $entirepart := dts:TranscriptionPassageNodes($text, $level1, $level2)
                        return
                        <TEI xmlns="http://www.tei-c.org/ns/1.0" >
                            <dts:fragment xmlns:dts="https://w3id.org/dts/api#">
                                {$entirepart}
                            </dts:fragment>
                       </TEI>
                else (
                  let $pass:= dts:parsePassage($ref)
                        let $level1 := $pass//s:group[@nr=1] 
                        let $level2 := $pass//s:group[@nr=3] 
                        let $entirepart := dts:EditionPassageNodes($text, $level1, $level2)
                        return
                        <TEI xmlns="http://www.tei-c.org/ns/1.0" >
                            <dts:fragment xmlns:dts="https://w3id.org/dts/api#">
                                {$entirepart}
                            </dts:fragment>
                       </TEI>
                
                )       
         
(:         if there are start and end, look for a range:)
else if($start != '' or $end != '') then (

let $parsedURN := dts:parseDTSURN($id)
let $parsedid := $parsedURN//s:group[@nr=3]/text()

return 
        if (contains($id,'betmasMS'))  
        then 
(:       it is a manuscript transcription :)
        (
         let $from:= dts:parsePassage($start)
         let $to :=dts:parsePassage($end)
                    let $frompage := $from//s:group[@nr=1]//text() 
                    let $fromcolumn := $from//s:group[@nr=3]//text() 
                    let $topage := $to//s:group[@nr=1]//text()
                    let $tocolumn := $to//s:group[@nr=3]//text() 
                    let $div1 := $text//t:pb[@n=$frompage]/ancestor::t:div/@n
                    let $part1 := dts:TranscriptionPassageNodes($text, $frompage, $fromcolumn)
                    let $div2 := $text//t:pb[@n=$topage]/ancestor::t:div/@n
                    let $part2 :=  dts:TranscriptionPassageNodes($text, $topage, $tocolumn)
                    let $middle := $text//t:ab[parent::t:div[(number(@n) gt number(string($div1))) and (number(@n) lt number(string($div2)))]]/node()
                     let $all := ($part1, $middle,$part2)
                      return 
                      
                      <TEI xmlns="http://www.tei-c.org/ns/1.0">
                            <dts:fragment xmlns:dts="https://w3id.org/dts/api#">
                                {$all}
                             </dts:fragment>
                        </TEI>
                                   
        )
        else 
(:        it is a literary work:)
        (
         let $from:= dts:parsePassage($start)
         let $to :=dts:parsePassage($end)
                    let $fromlevel1 := $from//s:group[@nr=1]//text()
                    let $fromlevel2 := $from//s:group[@nr=3]//text() 
                    let $tolevel1 := $to//s:group[@nr=1]//text()
                    let $tolevel2 := $to//s:group[@nr=3]//text() 
                    let $part1 := dts:EditionPassageNodesRange($text, $fromlevel1, $fromlevel2, 'start')
                    let $part2 :=  dts:EditionPassageNodesRange($text, $tolevel1, $tolevel2, 'end')
                    let $middle := $text//t:*[parent::t:div[@type='edition']][(number(@n) gt number($fromlevel1))][(number(@n) lt number($tolevel1))]
                     let $all := ($part1, $middle,$part2)
                      return 
                      
                      <TEI xmlns="http://www.tei-c.org/ns/1.0" >
                            <dts:fragment xmlns:dts="https://w3id.org/dts/api#">
                                {$all}
                                
                                </dts:fragment>
                                </TEI>
        )
)
                       
else $file 

                       
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
    <http:header name="location" value="/api/dts/collections?id=urn:dts"/>
  </http:response>
</rest:response>) else
let $parsedURN := dts:parseDTS($id)
let $BMid := $parsedURN//s:group[@nr=3]
let $file:= persdts:fileingit($id, $BMid, $sha)
let $text := $file//t:div[@type='edition']
let $textType := $file//t:objectDesc/@form
let $passage := if (contains($id, 'betmasMS:')) then (
                                                (:manuscripts:)
                                if($ref='' and $level = '' and $start ='' and $end = ''and $groupBy = '' and $max = '') 
                                then for $n in $text/t:div/@n return <p>{string($n)}<type>folio</type></p>
                               else if($level != '') 
                                then if ($level = '2') 
                                            then for $n in $text//t:pb[@n] return <p>{(string($n/@n))}<type>page</type></p>
                                          else if ($level = '3')
                                           then for $n in $text//t:cb[@n] return <p>{(string($n/preceding-sibling::t:pb[@n][1]/@n)||string($n/@n))}<type>column</type></p>
                                          else  () 
                                 else if($ref != '') 
                               then 
                               let $combos := for $pb in $text/t:div[@n=$ref]/descendant::t:pb[@n] 
                                         for $cb in $pb/following-sibling::t:cb[@n] 
                                         return string($pb/@n)||string($cb/@n)
                              for $c in distinct-values($combos)
                              return <p>{$c}</p>
                                       
                               else ()
) else 
(:works. some are encoded with a basic nested divs structure, some instaed, especially bible texts use l :)
                                if($ref='' and $level = '' and $start ='' and $end = ''and $groupBy = '' and $max = '') 
                                then  for $n in $text/t:* return 
                                <p>
                                         {string($n/@n )}
                                         {if($n/@subtype) then <type>{string($n/@subtype)}</type> else ()}
                                         {if($n/@corresp) then <title>{titles:printTitleMainID($n/@corresp)}</title> 
                                            else if($n/t:label) then <title>{$n/t:label/string()}</title> else ()}
                                          </p>
                              else if($ref != '' and $start = '') 
                               then   for $n in $text/t:div[@n=$ref]/descendant::t:*[@n] return 
                               
                               
                               <p>
                                         {($ref || '.'|| string($n/@n))}
                                         {if($n/@subtype) then <type>{string($n/@subtype)}</type> else ()}
                                         {if($n/@corresp) then <title>{titles:printTitleMainID($n/@corresp)}</title> 
                                            else if($n/t:label) then <title>{$n/t:label/string()}</title> else ()}
                                          </p>
                               
                             else if($level = '2' and $start = '') 
                                then 
                                if($ref != '') then 
                                                        for $n in ($text/t:div[@n=$ref]/t:div[@n], $text/t:div[@n=$ref]/t:ab/t:l[@n]) 
                                                        return 
                                         <p>
                                         {(string($n/ancestor::t:*[@n][1]/@n) ||'.' || string($n/@n))}
                                         <type>verse</type>
                                          </p>
                                                else
                                                
                                                      for $n in ($text/t:div[@n]/t:div[@n], $text/t:div[@n]/t:ab/t:l[@n]) return 
                                          <p>
                                         {(string($n/ancestor::t:*[@n][1]/@n) ||'.' || string($n/@n))}
                                         <type>verse</type>
                                          </p>
                             
                            else if($start != '' and $end != '') 
                               then if ($level != '') then (
                                  if ($level = '2') then 
                                  let $range := $text/t:div[number(@n) ge number($start)][number(@n) le number($end)] 
                                  return 
                                  for $n in ($range/t:div[@n], $range/t:ab/t:l[@n]) 
                                  return 
                                   <p>
                                         {(string($n/ancestor::t:*[@n][1]/@n) ||'.' || string($n/@n))}
                                         <type>verse</type>
                                          </p>
                                   else ()
                               )
                               
                               else for $n in $text/t:div[number(@n) ge number($start)][number(@n) le number($end)] return 
                               <p>
                                         {string($n/@n)}
                                         {if($n/@subtype) then <type>{string($n/@subtype)}</type> else ()}
                                         {if($n/@corresp) then <title>{titles:printTitleMainID($n/@corresp)}</title> 
                                            else if($n/t:label) then <title>{$n/t:label/string()}</title> else ()}
                                          </p>
                             
                             else ()
(:                             the following step should take the list of results and format it using the chunksize and max parameters:)
let $CS := number($groupBy)
let $M := number($max)

let $ctype := if(contains($id, 'betmasMS:')) then 
 (if($level = '') then 'folio' else if($level='2') then 'page' else 'column')
                                else 
                                (if($level = '') then (let $types := for $t in $text/t:div
                                            let $typ := if($t/@subtype) then string($t/@subtype) else 'textpart'
                                                                    group by $T := $typ 
                                                                    let $count := count($T)
                                                                    return <t tot="{$count}">{$T}</t>
                                                                    return $types[max(@tot)]/text())
                                 else  if($level = '2') then (
                                 if($text/t:div/t:ab/t:l) then 'verse'
                                 else
                                 let $types :=  for $t in $text/t:div/t:div
                                            let $typ := if($t/@subtype) then string($t/@subtype) else 'textpart'
                                               group by $T := $typ 
                                             let $count := count($T)
                                                                    return <t tot="{$count}">{$T}</t>
                                  return $types[max(@tot)]/text()                        
                                                                    )
                             else 'textpart')
                             
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
                                                        let $chunck  := map {'start' :=  $passage[$rangeStart], 'end' := $passage[$rangeEnd]}
                                                       return 
                                                                    $chunck)
                                                else for $p in $passage 
                                                            let $refonly := map {"ref" := $p/text()}
                                                         let $refandtype := if((count($p/type) eq 1) and ($p/type/text() !=$ctype)) then map:put($refonly, 'dts:citeType', $p/type/text()) else $refonly
                                                         let $refTypeTitle :=
                                                         if(count($p/title) eq 1) then let $parttitle := map {"dc:title" := $p/title/text()} return map:put($refandtype, 'dts:dublincore', $parttitle) 
                                                         else              $refandtype
                                                         return 
                                                         $refTypeTitle
                                                 

(: regardless of passages sequence type (ranges as maps or items as strings) the following steps limits the number of results                                                :)
let $maximized :=if(string($max) !='') then for $p in subsequence($chunkedpassage, 1, $M) return $p else $chunkedpassage
let $cdepth := if(contains($id, 'betmasMS:')) then 3 
                                else 
                                       ( let $counts := for $div in ($text//t:div[@type='textpart'], $text//t:l) 
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
 log:add-log-message('/api/dts/cit/' || $id, xmldb:get-current-user(), 'dts'),
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
 case 'urn:dts:betmas' return
dts:mainColl($id, $countW, $w, $page, $nav)
case 'urn:dts:betmasMS' return
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
             "@id" : "urn:dts:betmas",
             "title" : "Beta maṣāḥǝft Textual Units",
             "description": "Collection of textual units of the Ethiopic tradition",
             "@type" : "Collection"
        },
        map{
             "@id" : "urn:dts:betmasMS",
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
function dts:Collection($id as xs:string*,$page as xs:integer*,$nav as xs:string*,$sha as xs:string*) {
if($id = '') then (
 <rest:response>
  <http:response status="302">
    <http:header name="location" value="/permanent/{$sha}/api/dts/collections?id=urn:dts"/>
  </http:response>
</rest:response>
) else
if(matches($id, '(urn:dts:?)(betmasMS:|betmas:)?([a-zA-Z\d]+)?(:)?(((\d+)(\w)?(\w)?((@)([\p{L}]+)(\[(\d+|last)\])?)?)?(\-)?((\d+)(\w)?(\w)?((@)([\p{L}]+)(\[(\d+|last)\])?)?)?)')) then
let $parsedURN := dts:parseDTS($id)
return
if (matches($parsedURN//s:group[@nr=3], '[a-zA-Z\d]+'))
then (
                let $specificID := $parsedURN//s:group[@nr=3]/text() 
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
let $eds := $doc//t:div[@type='edition']
let $document := if(count($eds) gt 1) then (if($eds[@xml:id = 'traces']) then $eds[@xml:id = 'traces'] else $eds[1]) else $doc//t:div[@type='edition']
return
if(count($doc) eq 1) then (
$config:response200JsonLD,
let $shortid:=substring-before($id, concat(':',$bmID))
let $memberInfo := persdts:member($shortid,$document, $sha)
let $addcontext := map:put($memberInfo, "@context", $dts:context)
let $addnav := if($nav = 'parent') then 
let $parent :=if(contains($id, 'betmasMS:')) then 
        map{
             "@id" : "urn:dts:betmasMS",
             "title" : "Beta maṣāḥǝft Manuscripts",
             "description": "Collection of Ethiopic Manuscript trasncriptions",
             "@type" : "Collection"
        }
        else map {
             "@id" : "urn:dts:betmas",
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
(for $witness in $config:collection-rootMS//t:title[@ref = $id]
          let $root := root($witness)/t:TEI/@xml:id
          group by $groupkey := $root
          return string($groupkey))
let $declared := if(contains($collURN, 'MS')) then () else 
for $witness in $doc//t:witness/@corresp return string($witness)
let $witnesses := ($computed, $declared)
let $distinctW := for $w in distinct-values($witnesses) return 
                            map { "fabio:isManifestationOf" := "https://betamasaheft.eu/" || $w,
                            "@id" := "urn:dts:betmasMS:" || $w,
                                      "@type" := "lawd:AssembledWork"}
                                      
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
( map {'@value' := ($config:appUrl ||"/manuscript/"|| $id || '/viewer'),
'@type' := 'edm:WebResource',
                 "svcs:has_service" := map{'@value' := "https://betamasaheft.eu/api/iiif/"||$id||"/manifest",
                 '@type' := 'svcs:Service',
"dcterms:conformsTo":= "http://iiif.io/api/image",
"doap:implements":= "http://iiif.io/api/image/2/level1.json"
 }
        }
) else ()
let $addmanifest := if (count($manifest) ge 1) then map:put($ext, "foaf:depiction", $manifest) else $ext
let $parts := if(count($haspart) ge 1) then map:put($addmanifest, 'dcterms:hasPart', $haspart) else $addmanifest

let $dtsPass := "/permanent/"||$sha||"/api/dts/document?id=" || $resourceURN
let $dtsNav := "/permanent/"||$sha||"/api/dts/navigation?id=" || $resourceURN
let $download := "https://betamasaheft.eu/tei/" || $id || '.xml'
let $citeDepth :=  if(contains($collURN, 'MS')) then 3 else let $counts := for $div in ($document//t:div[@type='textpart'], $document//t:l) return count($div/ancestor::t:div)
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
dts:nestedDivs($document//t:div[@type='edition'])
            ]
let $c := count($document//t:div[@type='edition']//t:ab//text())
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
let $permapath := replace(persdts:capitalize-first(substring-after(base-uri($config:collection-root/id($bmID)[name()='TEI']), '/db/apps/BetMasData/')), $collection, '')
return 
doc('https://raw.githubusercontent.com/BetaMasaheft/' || $collection || '/'||$sha||'/'|| $permapath)//t:TEI
};
