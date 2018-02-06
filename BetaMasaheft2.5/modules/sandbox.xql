xquery version "3.1";

declare namespace t="http://www.tei-c.org/ns/1.0";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "titles.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace console = "http://exist-db.org/xquery/console";
import module namespace sparql="http://exist-db.org/xquery/sparql" at "java:org.exist.xquery.modules.rdf.SparqlModule";

collection($config:data-rootMS)/t:TEI[count(descendant::t:msPart) ge 3]
   
    