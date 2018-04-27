xquery version "3.1" encoding "UTF-8";
(:~
 : module used by text search query functions to provide alternative 
 : strings to the search, based on known homophones.
 : 
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)
module namespace wiki = "https://www.betamasaheft.uni-hamburg.de/BetMas/wiki";
import module namespace console = "http://exist-db.org/xquery/console";
declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace sr = "http://www.w3.org/2005/sparql-results#";

(:~this function makes a call to wikidata API :)
declare function wiki:wikitable($Qitem) {
let $sparql := 'SELECT ?viafid ?viafidLabel WHERE {
   wd:' || $Qitem || ' wdt:P214 ?viafid .
   SERVICE wikibase:label {
    bd:serviceParam wikibase:language "en" .
   }
 }'

let $query := 'https://query.wikidata.org/sparql?query='|| xmldb:encode-uri($sparql)

let $req := try{httpclient:get(xs:anyURI($query), false(), <headers/>)} catch *{$err:description}

let $viafId := $req//sr:result/sr:binding[@name="viafidLabel"]
let $WDurl := 'https://www.wikidata.org/wiki/'||$Qitem
let $VIAFurl := 'https://viaf.org/viaf/'||$Qitem
(:returns the result in another small table with links:)
return
<table class="table table-responsive">
<tbody>
<tr>
<td>WikiData Item</td>
<td><a target="_blank" href="{$WDurl}">{$Qitem}</a></td>
</tr>
<tr>
<td>VIAF ID</td>
<td><a target="_blank" href="{$VIAFurl}">{$viafId}</a></td>
</tr>
</tbody>
</table>
};