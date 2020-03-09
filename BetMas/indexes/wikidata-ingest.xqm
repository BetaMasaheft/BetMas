xquery version "3.0";

module namespace wdi="wikidata-ingest";
declare namespace sr="http://www.w3.org/2005/sparql-results#";

import module namespace http="http://expath.org/ns/http-client";

declare function wdi:viaf($Qid){
let $sparql := 'SELECT ?viafid ?viafidLabel WHERE {
   wd:' || $Qitem || ' wdt:P214 ?viafid .
   SERVICE wikibase:label {
    bd:serviceParam wikibase:language "en" .
   }
 }'

let $query := 'https://query.wikidata.org/sparql?query='|| xmldb:encode-uri($sparql)

let $req := try{let $request := <http:request href="{xs:anyURI($query)}" method="GET"/>
    return http:send-request($request)} catch *{$err:description}
    return
    $req//sr:result/sr:binding[@name="viafidLabel"]
    };

declare function wdi:title($Qid) {
(:  :let $Qid := 'wd:Q12418':)
  let $sparql := 'SELECT ?title WHERE {
  ' || $Qid || ' wdt:P1476 ?title .}'
  let $query := 'https://query.wikidata.org/sparql?query=' || xmldb:encode-uri($sparql)
  let $request := <http:request href="{$query}" method="GET"/>
  let $response := http:send-request($request)
  return $response//sr:result/sr:binding[@name = "title"]//text()
};

declare function wdi:date($Qid) {
  let $sparql := 'SELECT ?data WHERE {
  ' || $Qid || ' wdt:P571 ?data .}'
  let $query := 'https://query.wikidata.org/sparql?query=' || xmldb:encode-uri($sparql)
  let $request := <http:request href="{$query}" method="GET"/>
  let $response := http:send-request($request)
  return $response//sr:result/sr:binding[@name = "data"]//text()
};

declare function wdi:author($Qid) {
  let $sparql := 'SELECT ?author WHERE {
  ' || $Qid || ' wdt:P170 ?author .}'
  let $query := 'https://query.wikidata.org/sparql?query=' || xmldb:encode-uri($sparql)
  let $request := <http:request href="{$query}" method="GET"/>
  let $response := http:send-request($request)
  return $response//sr:result/sr:binding[@name = "author"]//text()
};