xquery version "3.1" encoding "UTF-8";
(:~
 : module with all the main functions which can be called by the API.
 : 
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)
module namespace apisparql = "https://www.betamasaheft.uni-hamburg.de/BetMas/api";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "titles.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace console = "http://exist-db.org/xquery/console";
import module namespace editors="https://www.betamasaheft.uni-hamburg.de/BetMas/editors" at "editors.xqm";
import module namespace sparql="http://exist-db.org/xquery/sparql" at "java:org.exist.xquery.modules.rdf.SparqlModule";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMas/string" at "tei2string.xqm";
    
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

declare variable $apisparql:response200 := $config:response200;

declare variable $apisparql:response200Json := $config:response200Json;
        
declare variable $apisparql:response200XML := $config:response200XML;
declare variable $apisparql:response200RDFXML := $config:response200RDFXML;
declare variable $apisparql:response200RDFJSON := $config:response200RDFJSON;

declare variable $apisparql:response400 := $config:response400;
        
declare variable $apisparql:response400XML := $config:response400XML;
declare variable $apisparql:prefixes := $config:sparqlPrefixes;

 declare
%rest:GET
%rest:path("/BetMas/api/SPARQL")
%rest:query-param("query", "{$query}", "")
%output:method("xml")
function apisparql:sparqlQuery($query as xs:string*) {

let $q := ((if(starts-with($query, 'PREFIX')) then () else $apisparql:prefixes) || normalize-space($query))  
let $xml := sparql:query($q)
return
($apisparql:response200XML,
$xml
)};

 declare
%rest:GET
%rest:path("/BetMas/api/RDFXML/{$collection}/{$id}")
%output:method("xml")
function apisparql:sparqlITEMgraph($collection as xs:string, $id as xs:string) {

let $xml := doc('/db/rdf/'||$collection||'/'||$id||'.rdf')//rdf:RDF
return
($apisparql:response200RDFXML,
$xml
)};

declare
%rest:GET
%rest:path("/BetMas/api/RDFJSON/{$collection}/{$id}")
%output:method("json")
function apisparql:sparqlITEMgraphJson($collection as xs:string, $id as xs:string) {

let $xml := doc('/db/rdf/'||$collection||'/'||$id||'.rdf')
let $json := apisparql:xml2json($xml/rdf:RDF)
return
($apisparql:response200RDFJSON,
$json
)};

 declare
%rest:GET
%rest:path("/BetMas/api/SPARQL/json")
%rest:query-param("query", "{$query}", "")
%output:method("json")
function apisparql:sparqljsonQuery($query as xs:string*) {

let $q := ((if(starts-with($query, 'PREFIX')) then () else $apisparql:prefixes) || normalize-space($query))  
let $xml := sparql:query($q)
return

($apisparql:response200Json,

let $json := apisparql:xml2json($xml/node())
return $json
)};

                                                             
declare function apisparql:xml2json($nodes as node()*){
 for $node in $nodes
    return
        typeswitch ($node)
         case element(rdf:RDF)
      
       return
(:        add to the map one key / value pair for each statement of the same kind:)
        map:merge( 
        for $description in $node/element()
(:                                             key:)  
               let $n := count($description/preceding-sibling::*) 
                                                         order by $n
                                    let $rdfabout :=  string($description/@rdf:about) 
                                   group by $about := $rdfabout
                                   order by $about
(:        value is an object:)
                                      let $rels := 
                                      map:merge( 
                                                         for $property in $description/element()
                                                         let $n := count($property/preceding-sibling::*) 
                                                         order by $n
                                                          let $pName := $property/name()
                                                         let $label := namespace-uri($property) 
                                                         let $pNlocal := substring-after($pName, ':')
                                                         let $pN := ($label||$pNlocal)
                                                         group by $PropName := $pN
                                                         return
                                                         let $thepairs := for $pair in $property 
                                                                              let $type := if($pair/@rdf:resource) then 'uri'  else if($pair/element()) then 'bnode' else 'literal'
                                                                              let $value := if($pair/@rdf:resource) then string($pair/@rdf:resource) else if ($pair/element()) then ('another node') else normalize-space($pair/text())
                                                                              let $pairmap :=  map {'type' := $type, 'value' := $value}
                                                                              let $withxmllang := if($pair/@xml:lang) then map:put($pairmap, 'xml:lang', string($pair/@xml:lang)) else $pairmap
                                                                              let $withtype := if($pair/@*:datatype) then map:put($withxmllang, 'datatype', string($pair/@*:datatype)) else $withxmllang
                                                                                 return 
                                                                               $withtype
                                                          let $pairs := if (count($thepairs) > 1) then $thepairs else [$thepairs]                     
                                                          return
                                                             map:entry( $PropName, $pairs)
                                      )
                                  return
                                    map:entry($about, $rels)
   
          )
(:            add to main map the about and its value :)
      
        case element(sr:sparql)
        return
        let $vars := for $var in $node/sr:head/sr:variable return $var/@*:name
        return
        map {"head":= map { "vars":= if(count($vars) = 1) then [$vars] else $vars},
                "results":= apisparql:xml2json($node/sr:results)
        }
        case element(sr:results)
        return 
        map {"bindings":= apisparql:xml2json($node/node())}       
       case element(sr:result)
        return 
      map:merge( for $x in $node/sr:binding 
       let $binding := apisparql:xml2json($x/node()) 
       return map{$x!@*:name := $binding}
       )
       case element(sr:bnode)
       return
       map {'type' := 'bnode', 'value' := $node/text()}
       case element(sr:uri)
      return
       
       let $uri := map {'type' := 'uri', 'value' := $node/text()}
        let $withxmllang := if($node/@xml:lang) then map:put($uri, 'xml:lang', $node/@xml:lang) else $uri
       let $withtype := if($node/@*:datatype) then map:put($withxmllang, 'datatype', $node/@*:datatype) else $withxmllang
       return 
       $withtype
       case element(sr:literal)
       return
       let $literal :=  map {'type' := 'literal', 'value' := $node/text()}
        let $withxmllang := if($node/@xml:lang) then map:put($literal, 'xml:lang', $node/@xml:lang) else $literal
       let $withtype := if($node/@*:datatype) then map:put($withxmllang, 'datatype', $node/@*:datatype) else $withxmllang
       return 
       $withtype
        case element()
                return
                    ()
            default
                return
                    ()
};

declare
%rest:GET
%rest:path("/BetMas/api/SPARQL/relations/{$id}")
%output:method("json")
function apisparql:sparqlQueryJSON($id as xs:string*) {

let $query := ((if(starts-with($query, 'PREFIX')) then () else $apisparql:prefixes) || "
SELECT ?r ?y 
WHERE {?x ?r bm:" || $id || " . 
?x crm:P48_has_preferred_identifier ?y}")
let $sparqlresults := sparql:query($query)
let $results := $sparqlresults//sr:result
return 
if(count($results) >= 1) then
($apisparql:response200Json,
for $result in $results
let $r := $result//sr:binding[1]//sr:uri/text()
let $y := $result//sr:binding[2]//sr:literal/text()
let $title := titles:printTitleMainID($y)
return

map {
'relation' := $r,
'id' := $title
}

)
else 
($apisparql:response200Json,
map {
'info' := 'sorry, no relations available in our RDF data'
}

)
};

declare
%rest:GET
%rest:path("/BetMas/api/SPARQL/versions/{$id}/{$chapterID}")
%output:method("json")
function apisparql:sparqlQuery($id as xs:string*, $chapterID as xs:string*) {


let $query := ((if(starts-with($query, 'PREFIX')) then () else $apisparql:prefixes) || "
SELECT ?otherVersionid
WHERE { 
   {bm:" || $id || " saws:isVersionOf ?MAIN . 
   ?MAIN crm:P48_has_preferred_identifier ?MAINid . 
   ?otherVersion saws:isVersionOf ?MAIN . 
   ?otherVersion crm:P48_has_preferred_identifier ?otherVersionid} 
   UNION 
   { ?version saws:isVersionOf bm:" || $id || " . 
   ?version crm:P48_has_preferred_identifier ?otherVersionid } 
   }"
)

let $sparqlresults := sparql:query($query)
let $results := $sparqlresults//sr:result
return 
if(count($results) >= 1) then
($apisparql:response200Json,
let $versions := 
for $result in $sparqlresults//sr:literal/text()[. != $id]
let $version := collection($config:data-rootW)//id($result)
let $resTit := titles:printTitleMainID($result)
let $texts :=
if ($version//t:div[contains(@corresp, $chapterID)])
then
    (for $edition in $version//t:div[@corresp[contains(., $chapterID)]]
    let $respsource := string($edition/parent::t:div[@type='edition']/@resp)
    let $resp:= if(starts-with($respsource, '#')) then (
    let $biblID := substring-after($respsource, '#') 
    let $bibl := $version//id($biblID)
    return
    string($bibl/t:ptr/@target)) else editors:editorKey($respsource)
    let $source := map{'id' := $result, 'title' := $resTit, 'ed' := $resp}
    let $text := normalize-space(string-join($edition//t:ab/text(), ' '))
    let $version := map{'source' := $source, 'text' := $text}
    return
    map {'version' := $version}
    )
        
else
    if (count($version//t:witness) eq 1) then (
        let $wit := string($version//t:witness/@corresp)
        let $uniqueWitness := collection($config:data-rootMS)//id($wit)
        let $titWit := titles:printTitleMainID($wit)
       let $source := map{'id' := $result, 'title' := $resTit, 'uniqueWitness' := $titWit}
       let $edition := $uniqueWitness//t:div[@corresp[contains(., $chapterID)]]
        return
            if ($edition) 
            then(
                
    let $text := normalize-space(string-join($edition//t:ab/text(), ' '))
    let $version := map{'source' := $source, 'text' := $text}
    return
    map {'version' := $version}
      )
      else(
                 let $text := 'no text available for ' || $resTit || ' (' || $result || ')'  || ' unique witness ' ||$titWit || ' (' || $wit || ')'
                 let $version := map{'source' := $source, 'text' := $text}
    return
    map {'version' := $version}
    )
    )
   else
        (
    let $source := map{'id' := $result, 'title' := $resTit}
    let $text := 'no text available for ' || $resTit || ' (' || $result || ')'
    let $version := map{'source' := $source, 'text' := $text}
    return
    map {'version' := $version}
    )
return
    $texts
return
map { 'versions' := $versions,
'total' := count($versions)

    }
)
else (
$apisparql:response200Json,
map {
'info' := 'sorry, no relations available in our RDF data'
}

)
};
