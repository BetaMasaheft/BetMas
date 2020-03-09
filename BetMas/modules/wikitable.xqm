xquery version "3.1" encoding "UTF-8";
(:~
 : module used by text search query functions to provide alternative 
 : strings to the search, based on known homophones.
 : 
 : @author Pietro Liuzzo 
 :)
module namespace wiki = "https://www.betamasaheft.uni-hamburg.de/BetMas/wiki";
declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace sr = "http://www.w3.org/2005/sparql-results#";
declare namespace http = "http://expath.org/ns/http-client";

(:~this function makes a call to wikidata API :)
declare 
%test:arg("Qitem", "Q38") %test:assertExists
function wiki:wikitable($Qitem) {
let $sparql := 'SELECT ?viafid ?viafidLabel WHERE {
   wd:' || $Qitem || ' wdt:P214 ?viafid .
   SERVICE wikibase:label {
    bd:serviceParam wikibase:language "en" .
   }
 }'

let $query := 'https://query.wikidata.org/sparql?query='|| xmldb:encode-uri($sparql)

let $req := try{let $request := <http:request href="{xs:anyURI($query)}" method="GET"/>
    return http:send-request($request)[2]} catch *{$err:description}
let $WDurl := 'https://www.wikidata.org/wiki/'||$Qitem
let $viafId := $req//sr:result/sr:binding[@name="viafidLabel"]
return 
if (count($viafId) ge 1) then 


(:returns the result in another small table with links:)
<div class="w3-responsive">
<table class="w3-table w3-hoverable">
<tbody>
<tr>
<td>WikiData Item</td>
<td><a target="_blank" href="{$WDurl}">{$Qitem}</a></td>
</tr>
<tr>
<td>VIAF ID</td>
<td>{for $v in $viafId return (<a target="_blank" href="https://viaf.org/viaf/{$v}">{$v}</a>,<br/>)}</td>
</tr>
</tbody>
</table></div>
else (
<div class="w3-responsive">
<table class="w3-table w3-hoverable">
<tbody>
<tr>
<td>WikiData Item</td>
<td><a target="_blank" href="{$WDurl}">{$Qitem}</a></td>
</tr>
</tbody>
</table></div>
)
};