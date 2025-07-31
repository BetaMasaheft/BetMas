xquery version "3.1" encoding "UTF-8";
(:~
 : The module is aimed at interactions between the application and a Fuseki SPARQL API. https://jena.apache.org/documentation/fuseki2/index.html
 :
 : @author Pietro Liuzzo
 : with load of help from Ethan Gruber
 :)
module namespace fusekisparql = 'https://www.betamasaheft.uni-hamburg.de/BetMasWeb/sparqlfuseki';
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";

declare namespace http = "http://expath.org/ns/http-client";
declare namespace sr = "http://www.w3.org/2005/sparql-results#";

(:Assumes that Fuseki is running in Tomcat, and that Tomcat server.xml has been edited to run on port 8081, instead of 8080. :)
(: Note: the version in BetMas had port 8081, in BetMasWeb 3030 :)
declare variable $fusekisparql:port := 'http://localhost:3030/fuseki/';


(:~ given a SPARQL query this will pass it to the selected dataset  and return SPARQL Results in XML:)
declare function fusekisparql:query($dataset, $query) {
    let $format := if(contains($query, 'CONSTRUCT')) then 'format=xml&amp;' else ()
    let $url := concat($fusekisparql:port||$dataset||'/query?'||$format||'query=', encode-for-uri($query))
    let $request := <http:request href="{xs:anyURI($url)}" method="GET"/>
    let $file := http:send-request($request)
    return
        $file
};


(:~ given a SPARQL Update input for the type of operation (INSERT or DELETE),  the triples to be added in the SPARQL Update and the destination
dataset, this function will send a POST request to the location of a running Fuseki instance and perform the operation:)
declare function fusekisparql:update($dataset, $InsertOrDelete, $triples) {
    let $url := $fusekisparql:port||$dataset||'/update'
    let $sparqlupdate := $config:sparqlPrefixes || $InsertOrDelete || ' DATA
{
  '||$triples||'
}'
    let $req :=
    <http:request
        http-version="1.1"
        href="{xs:anyURI($url)}"
        method="POST">
        <http:header
            name="Content-type"
            value="application/sparql-update"></http:header>
        <http:body
            media-type="text/plain">{$sparqlupdate}</http:body>
    </http:request>
    let $post := http:send-request($req)[2]
    return
        $post
};