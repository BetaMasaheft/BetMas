xquery version "3.1";


import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
(: namespaces of data used :)
declare namespace t = "http://www.tei-c.org/ns/1.0";

for $e in subsequence(collection($config:data-rootW), 1, 10)
let $languages := distinct-values($e//@xml:lang)
let $declared := distinct-values($e//t:language/@ident)
let $ident := $e//t:language[@ident[not(. = $languages)]]/@ident
return string($e/t:TEI/@xml:id)|| ' -->' || string-join($languages, ',') || ' <-- attested in xml:lang, but declared ' || string-join($declared, ',') ||'. Thus falsly declared --> ' || string-join($ident, ',')