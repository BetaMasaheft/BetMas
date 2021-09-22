xquery version "3.1" encoding "UTF-8";
(:~
 : module with all the main functions which can be called by the API.
 : called by academics.js
 : 
 : @author Pietro Liuzzo 
 :)
module namespace aka = "https://www.betamasaheft.uni-hamburg.de/BetMas/aka";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMas/string" at "xmldb:exist:///db/apps/BetMas/modules/tei2string.xqm";
import module namespace wiki="https://www.betamasaheft.uni-hamburg.de/BetMas/wiki" at "xmldb:exist:///db/apps/BetMas/modules/wikitable.xqm";

declare namespace t = "http://www.tei-c.org/ns/1.0";


(: For REST annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";


declare
%rest:GET
%rest:path("/BetMas/api/academics")
%output:method("json")
function aka:academics(){
for $academic in  collection($config:data-rootPr)//t:occupation[@type eq 'academic']
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
let $wikidata := if(starts-with($p/@sameAs, 'wd:')) then wiki:wikitable(substring-after($p/@sameAs, 'wd:')) else ('No Wikidata ID')
order by $mindate
return
map {
'id' : string($id),
'title' : $title,
'text' : $academictext,
'dates' : $d-d,
'bio' : $bio,
'zoturl' : $zoterurl,
'wd' : $wikidata
}

};
