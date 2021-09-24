xquery version "3.1" encoding "UTF-8";
(:~
 : module with all the main functions which can be called by the API.
 : 
 : @author Pietro Liuzzo 
 :)
module namespace api = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/api";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMas/switch2"  at "xmldb:exist:///db/apps/BetMas/modules/switch2.xqm";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMas/modules/log.xqm";
import module namespace all="https://www.betamasaheft.uni-hamburg.de/BetMas/all" at "xmldb:exist:///db/apps/BetMas/modules/all.xqm";
import module namespace dts="https://www.betamasaheft.uni-hamburg.de/BetMas/dts" at "xmldb:exist:///db/apps/BetMas/modules/dts.xqm";
import module namespace editors="https://www.betamasaheft.uni-hamburg.de/BetMas/editors" at "xmldb:exist:///db/apps/BetMas/modules/editors.xqm";
import module namespace wiki="https://www.betamasaheft.uni-hamburg.de/BetMas/wiki" at "xmldb:exist:///db/apps/BetMas/modules/wikitable.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace viewItem = "https://www.betamasaheft.uni-hamburg.de/BetMas/viewItem" at "xmldb:exist:///db/apps/BetMas/modules/viewItem.xqm";
import module namespace kwic = "http://exist-db.org/xquery/kwic"
    at "resource:org/exist/xquery/lib/kwic.xql"; 


import module namespace fusekisparql = 'https://www.betamasaheft.uni-hamburg.de/BetMas/sparqlfuseki' at "xmldb:exist:///db/apps/BetMas/fuseki/fuseki.xqm";
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


       
   

declare 
%rest:GET
%rest:path("/api/listRepositoriesName")
%output:method("html")
function api:listRepositoriesName()
{
for $i in doc('/db/apps/lists/institutions.xml')//t:item
let $name := $i/text()
order by $name
return
<option value="{string($i/@xml:id)}">{$name}</option>
};


declare 
%rest:GET
%rest:path("/api/cataloguesZotero")
%output:method("html")
function api:getcataloguesZotero()
{
for $catalogue in doc('/db/apps/lists/catalogues.xml')//t:item
let $sorting := $catalogue//text()[1]
order by $sorting
return
<option value="{replace(string($catalogue/@xml:id), 'bm_', '')}">{$catalogue//text()}</option>
};


(:given a work id returns the witnesses of works in which this is contained:)
declare

%rest:GET
%rest:path("/api/witnessesOfContainer/{$id}")
%output:method("json")
function api:witnessesOfContainerWork($id as xs:string*){
let $id := if(starts-with($id, $config:baseURI)) then string($id) else $config:baseURI || string($id)
let $corresps := $dts:collection-rootW//t:div[@type eq 'textpart'][@corresp eq  $id]
for $c in $corresps 
let $workid := string(root($c)/t:TEI/@xml:id )
let $witnesses := $dts:collection-rootMS//t:title[contains(@ref, $workid)]
let $witnessesID := for $w in $witnesses let $wid :=  string(root($w)/t:TEI/@xml:id ) return  titles:printTitleMainID($wid)
let $tit := titles:printTitleMainID($workid)
return 
map {'containerWork' : $tit,
'witnesses' : config:distinct-values($witnessesID)
}
};

(:displayes on the hompage the totals of the portal:)
declare

%rest:GET
%rest:path("/api/count")
%output:method("json")
function api:count(){
 ($api:response200Json,
let $total := count($titles:collection-root)
let $totalMS := count($dts:collection-rootMS)
let $totalInstitutions := count(collection($config:data-rootIn))
let $totalWorks := (count($dts:collection-rootW) + count(collection($config:data-rootN)))
let $totalPersons := count(collection($config:data-rootPr))
return 

map {
'total' :$total, 
'totalMS' : $totalMS,
'totalInstitutions' : $totalInstitutions,  
'totalWorks' : $totalWorks, 
'totalPersons' : $totalPersons
 }
 )
};

(:displaies on the hompage the totals of the portal:)
declare

%rest:GET
%rest:path("/api/latest")
%output:method("json")
function api:latest(){
 ($api:response200Json,

let $twoweekago := current-date() - xs:dayTimeDuration('P15D')
let $coll := collection($config:data-root)//t:TEI
for $doc in  xmldb:find-last-modified-since($coll, $twoweekago)
let $id := string($doc/@xml:id)
let $filename := ($id|| '.xml')
let $baseUri := base-uri($doc)
let $docColl := substring-before($baseUri, $filename)
let $latest := for $c in $doc//t:change order by xs:date($c/@when) descending return $c
return
map { 'id' : $id,
'title' : titles:printTitleMainID($id),
'when' : xmldb:last-modified($docColl, $filename),
'who' : editors:editorKey($latest[1]/@who),
'what' : $latest[1]/text()
}
 )
};



  
(:~transforms into string text a single part of a tei file, e.g. a single node which contains many references to persons, places etc.:)
declare
%rest:GET
%rest:path("/api/string/{$id}")
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
%rest:path("/api/xmlpart/{$id}")
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


(:~retrives a single part of a tei file given a URI as formatted in the RDF, e.g. a single node:)
declare
%rest:GET
%rest:path("/api/{$id}/{$type}/{$subid}")
%output:method("xml")
%test:args("BNFet102", "addition", "e1") 
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
    <fragment xmlns="https://betamasaheft.eu/" source="https://betamasaheft.eu/{$id}">{
    $e
    }</fragment>
    )
};



(:~gets the formatted content of an addition in an item, given the id of the file and that of the addition item :)
declare
%rest:GET
%rest:path("/api/additions/{$id}/addition/{$addID}")
%output:method("xml")
%test:args("BAVet1", "a4") %test:assertExists
function api:additiontext($id as xs:string*, $addID as xs:string*){
let $log := log:add-log-message('/api/additions/'||$id||'/addition/'||$addID, sm:id()//sm:real/sm:username/string() , 'REST')
let $entity := $titles:collection-root/id($id)
let $a := $entity//t:item[@xml:id = $addID]
return
<div xmlns="https://www.w3.org/1999/xhtml" >{
viewItem:q($a)
}</div>
    
};



(:~ returns the relation element with the author attribution :)

declare 
%rest:GET
%rest:path("/api/{$id}/author")
%output:method("xml")
%test:arg("id","LIT1032Agains") %test:assertXPath("//@name[. = 'saws:isAttributedToAuthor']")
%test:arg("id","BAVet1") %test:assertEquals('<rest:response xmlns:rest="http://exquery.org/ns/restxq"><http:response xmlns:http="http://expath.org/ns/http-client" status="400"><http:header name="Content-Type" value="application/xml; charset=utf-8"/></http:response></rest:response>','<sorry>no info</sorry>')
function api:getauthorfromrelation($id as xs:string*) {
let $item :=$dts:collection-rootW/id($id)
return 

if($item//t:relation[@name eq  'saws:isAttributedToAuthor']) then (

log:add-log-message('/api/' || $id || '/author', sm:id()//sm:real/sm:username/string() , 'REST'),
$api:response200XML,
        $item//t:relation[@name eq  'saws:isAttributedToAuthor']
        )
        else 
        (
        $api:response400XML,
        <sorry>no info</sorry>
        )
};





(:~ returns a xml fragment with the element in a resource which has the given anchor:)
declare
%rest:GET
%rest:path("/api/otherMssText/{$id}/{$SUBid}")
%rest:query-param("element", "{$element}", "")
%output:method("xml")
%test:args('IVefiopsk1', 'a1', 'item') %test:assertXPath('//element')
function api:get-othertext($id as xs:string, $SUBid as xs:string, $element as xs:string*) {

let $log := log:add-log-message('/api/otherMssText/' || $id || '/' || $SUBid, sm:id()//sm:real/sm:username/string() , 'REST')  
  let $login := xmldb:login($config:data-root, $config:ADMIN, $config:ppw)
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
%rest:path("/api/xml/{$id}")
%output:method("xml")
%test:arg('id', 'LIT1367Exodus') %test:assertXPath('//contains')
function api:get-workXML($id as xs:string) {

    let $log := log:add-log-message('/api/xml/' || $id, sm:id()//sm:real/sm:username/string() , 'REST')
    let $login := xmldb:login($config:data-root, $config:ADMIN, $config:ppw)
    return
        
        ($api:response200XML,
        let $collection := 'works'
        let $item := api:get-tei-rec-by-ID($id)
        let $recordid := $item/t:TEI/@xml:id
        return
            if ($item//t:div[@type eq  'edition'])
            then
                <work>
                    <id>{data($recordid)}</id>
                    <text>{$item//t:div[@type eq  'edition']//text()}</text>
                    <contains>
                        {
                            for $subtype in $item//t:div[@type eq  'edition']/t:div[@subtype]
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
if($item//t:titleStmt/t:title[@type eq 'short']) then $item//t:titleStmt/t:title[@type eq 'short']/text() else $item//t:titleStmt/t:title[@xml:id eq 't1']/text()};


(:~ given the file id, returns the source TEI xml:)
declare
%rest:GET
%rest:path("/api/{$id}/tei")
%output:media-type("text/xml")
%output:method("xml")
%test:arg('id','LIT1367Exodus') %test:assertXPath("//*:text")
function api:get-tei-by-ID($id as xs:string) {
    let $log := log:add-log-message('/api/' || $id || '/tei', sm:id()//sm:real/sm:username/string() , 'REST')
    let $login := xmldb:login($config:data-root, $config:ADMIN, $config:ppw)
    return
        ($api:response200XML,
        api:get-tei-rec-by-ID($id)
        )
};

(:~ given the file id, returns the source TEI xml:)
declare
%rest:GET
%rest:path("/api/post/{$id}/tei")
%output:media-type("text/xml")
%output:method("xml")
%test:arg('id','LIT1367Exodus') %test:assertXPath("//*:text")
function api:get-POSTPROCESSED-tei-by-ID($id as xs:string) {
    let $log := log:add-log-message('/api/post/' || $id || '/tei', sm:id()//sm:real/sm:username/string() , 'REST')
    let $doc :=api:get-tei-rec-by-ID($id)
    return
        ($api:response200XML,
$doc        )
};

(:~ given the file id, returns the source TEI in a json serialization:)
declare
%rest:GET
%rest:path("/api/{$id}/json")
%output:method("json")
function api:get-tei2json-by-ID($id as xs:string) {
    
    let $log := log:add-log-message('/api/' || $id || '/json', sm:id()//sm:real/sm:username/string() , 'REST')
    let $login := xmldb:login($config:data-root, $config:ADMIN, $config:ppw)
    return
        ($api:response200Json,
        <json:value>{api:get-tei-rec-by-ID($id)}</json:value>
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
    $titles:collection-root/id($id)
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

