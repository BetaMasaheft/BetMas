xquery version "3.0";

module namespace tests="https://www.betamasaheft.uni-hamburg.de/BetMas/tests";

declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace functx = "http://www.functx.com";
declare namespace exist = "http://exist.sourceforge.net/NS/exist";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace s = "http://www.w3.org/2005/xpath-functions";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace validation = "http://exist-db.org/xquery/validation";
import module namespace app = "https://www.betamasaheft.uni-hamburg.de/BetMas/app" at "app.xqm";
import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace kwic = "http://exist-db.org/xquery/kwic"
    at "resource:org/exist/xquery/lib/kwic.xql";
import module namespace console="http://exist-db.org/xquery/console";
import module namespace httpclient="http://exist-db.org/xquery/httpclient";


(:checks that the titles of the repositories are printed correctly:)
declare function tests:testRepositoriesTitles(){
for $i in collection('/db/apps/BetMas/data/institutions/')
let $id := string($i//t:TEI/@xml:id)
let $name := base-uri($i)
return
try {app:printTitleID($id)}
catch * {<error>Caught error{$err:code} in {$name} : {$err:description}</error>}
};


declare function tests:testTabot(){
for $tabot in collection('/db/apps/BetMas/data/institutions/')//t:TEI//t:ab[@type='tabot']/t:persName/@ref
             let $tabotID := string($tabot)
	return
	try {app:printTitleID($tabotID)}
catch * {<error>Caught error{$err:code} in {$tabot} : {$err:description}</error>}
};