xquery version "3.0";
(:~
 : A set of helper functions to access the application context from
 : within a module.
 :)
module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config";

import module namespace http="http://expath.org/ns/http-client";

declare namespace templates="http://exist-db.org/xquery/templates";

declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";
declare namespace jmx="http://exist-db.org/jmx";

declare variable $config:sparqlPrefixes := "PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
         PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
         PREFIX lawd: <http://lawd.info/ontology/>
         PREFIX oa: <http://www.w3.org/ns/oa#>
         PREFIX ecrm: <http://erlangen-crm.org/current/>
         PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
         PREFIX gn: <http://www.geonames.org/ontology#>
         PREFIX agrelon: <http://d-nb.info/standards/elementset/agrelon.owl#>
         PREFIX rel: <http://purl.org/vocab/relationship/>
         PREFIX dcterms: <http://purl.org/dc/terms/>
         PREFIX bm: <https://betamasaheft.eu/>
         PREFIX pelagios: <http://pelagios.github.io/vocab/terms#>
         PREFIX syriaca: <http://syriaca.org/documentation/relations.html#>
         PREFIX saws: <http://purl.org/saws/ontology#>
         PREFIX snap: <http://data.snapdrgn.net/ontology/snap#>
         PREFIX pleiades: <https://pleiades.stoa.org/>
         PREFIX wd: <https://www.wikidata.org/>
         PREFIX dc: <http://purl.org/dc/elements/1.1/>
         PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
         PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
         PREFIX t: <http://www.tei-c.org/ns/1.0>
         PREFIX geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
         PREFIX foaf: <http://xmlns.com/foaf/0.1/>
         PREFIX sdc: <https://w3id.org/sdc/ontology#>";

declare variable $config:appUrl := 'https://betamasaheft.eu';
declare variable $config:DOI := '10.25592/BetaMasaheft';

declare variable $config:response200 := <rest:response>
        <http:response
            status="200">
                
            <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"
                    />
        </http:response>
    </rest:response>;
    
    declare variable $config:response404 := <rest:response>
        <http:response
            status="404">
                
        </http:response>
    </rest:response>;

declare variable $config:response200Json := <rest:response>
            <http:response
                status="200">
                <http:header
                    name="Content-Type"
                    value="application/json; charset=utf-8"/>
                <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"
                    />
            </http:response>
        </rest:response>;
        
        declare variable $config:response200JsonLD := <rest:response>
            <http:response
                status="200">
                <http:header
                    name="Content-Type"
                    value="application/ld+json; charset=utf-8"/>
                <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"
                    />
            </http:response>
        </rest:response>;
        
           declare variable $config:response404JsonLD := <rest:response>
            <http:response
                status="404">
                <http:header
                    name="Content-Type"
                    value="application/ld+json; charset=utf-8"/>
                <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"
                    />
            </http:response>
        </rest:response>;
        
         declare variable $config:response400JsonLD := <rest:response>
            <http:response
                status="400">
                <http:header
                    name="Content-Type"
                    value="application/ld+json; charset=utf-8"/>
                <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"
                    />
            </http:response>
        </rest:response>;
        
declare variable $config:response200XML := <rest:response>
            <http:response
                status="200">
                <http:header
                    name="Content-Type"
                    value="application/xml; charset=utf-8"/>
                <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"
                    />
            </http:response>
        </rest:response>;
        
        declare variable $config:response200TEIXML := <rest:response>
            <http:response
                status="200">
                <http:header
                    name="Content-Type"
                    value="application/tei+xml; charset=utf-8"/>
                <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"
                    />
            </http:response>
        </rest:response>;
        
        declare variable $config:response200RDFXML := <rest:response>
            <http:response
                status="200">
                <http:header
                    name="Content-Type"
                    value="application/rdf+xml; charset=utf-8"/>
                <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"
                    />
            </http:response>
        </rest:response>;
        
        declare variable $config:response200RDFJSON := <rest:response>
            <http:response
                status="200">
                <http:header
                    name="Content-Type"
                    value="application/rdf+json; charset=utf-8"/>
                <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"
                    />
            </http:response>
        </rest:response>;

declare variable $config:response400 := <rest:response>
            <http:response
                status="400">
                <http:header
                    name="Content-Type"
                    value="application/json; charset=utf-8"/>
            </http:response>
        </rest:response>;
        
declare variable $config:response400XML := <rest:response>
            <http:response
                status="400">
                <http:header
                    name="Content-Type"
                    value="application/xml; charset=utf-8"/>
            </http:response>
        </rest:response>;

declare variable $config:ADMIN := environment-variable('ExistAdmin');
declare variable $config:ppw := environment-variable('ExistAdminPw');


declare variable $config:app-root := 
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/modules")
;

declare variable $config:app-title := "Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea" ;
declare variable $config:xslt-root := $config:app-root || "/xslt";
declare variable $config:data-root := "/db/apps/BetMasData";
declare variable $config:schema-root := $config:app-root || "/schema";
declare variable $config:data-rootMS := $config:data-root || "/manuscripts";
declare variable $config:data-rootN := $config:data-root || "/narratives";
declare variable $config:data-rootW := $config:data-root || "/works";
declare variable $config:data-rootPl := $config:data-root || "/places";
declare variable $config:data-rootPr := $config:data-root || "/persons";
declare variable $config:data-rootIn := $config:data-root || "/institutions";
declare variable $config:data-rootA := $config:data-root || "/authority-files";
declare variable $config:data-rootCh := $config:data-root || "/Chojnacki";
declare variable $config:data-rootTraces := $config:app-root || "/traces";


declare variable $config:repo-descriptor := doc(concat($config:app-root, "/repo.xml"))/repo:meta;

declare variable $config:expath-descriptor := doc(concat($config:app-root, "/expath-pkg.xml"))/expath:package;

(:~
 : Resolve the given path using the current application context.
 : If the app resides in the file system,
 :)
declare function config:resolve($relPath as xs:string) {
    if (starts-with($config:app-root, "/db")) then
        doc(concat($config:app-root, "/", $relPath))
    else
        doc(concat("file://", $config:app-root, "/", $relPath))
};

declare function config:get-configuration() as element(configuration) {
    doc(concat($config:app-root, "/configuration.xml"))/configuration
};

(:~
 : Returns the repo.xml descriptor for the current application.
 :)
declare function config:repo-descriptor() as element(repo:meta) {
    $config:repo-descriptor
};

(:~
 : Returns the expath-pkg.xml descriptor for the current application.
 :)
declare function config:expath-descriptor() as element(expath:package) {
    $config:expath-descriptor
};

declare %templates:wrap function config:app-title($node as node(), $model as map(*)) as text() {
    $config:expath-descriptor/expath:title/text()
};


declare function config:app-meta-rest(){
    <meta xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $author in $config:repo-descriptor/repo:author
    return
        <meta xmlns="http://www.w3.org/1999/xhtml" name="creator" content="{$author/text()}"/>
};
declare function config:app-meta($node as node(), $model as map(*)) as element()* {
    <meta xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $author in $config:repo-descriptor/repo:author
    return
        <meta xmlns="http://www.w3.org/1999/xhtml" name="creator" content="{$author/text()}"/>
};

(:~
 : For debugging: generates a table showing all properties defined
 : in the application descriptors.
 :)
declare function config:app-info($node as node(), $model as map(*)) {
    let $expath := config:expath-descriptor()
    let $repo := config:repo-descriptor()
    return
        <table class="app-info">
            <tr>
                <td>app collection:</td>
                <td>{$config:app-root}</td>
            </tr>
            {
                for $attr in ($expath/@*, $expath/*, $repo/*)
                return
                    <tr>
                        <td>{node-name($attr)}:</td>
                        <td>{$attr/string()}</td>
                    </tr>
            }
            <tr>
                <td>Controller:</td>
                <td>{ request:get-attribute("$exist:controller") }</td>
            </tr>
        </table>
        
        
};


declare function config:get-data-dir() as xs:string? {
    try {
        let $request := <http:request http-version="1.1" method="GET" href="http://localhost:8080/{request:get-context-path()}/status?c=disk"/>
        let $response := http:send-request($request)
        return
            if ($response[1]/@status eq  "200") then
                let $dir := $response[2]//jmx:DataDirectory/string()
                return
                    if (matches($dir, "^\w:")) then
                        (: windows path? :)
                        "/" || translate($dir, "\", "/")
                    else
                        $dir
            else
                ()
    } catch * {
        ()
    }
};


declare function config:get-repo-dir() {
    let $dataDir := config:get-data-dir()
    let $pkgRoot := $config:expath-descriptor/@abbrev || "-" || $config:expath-descriptor/@version
    return
        if ($dataDir) then
            $dataDir || "/expathrepo/fonts-0.1"
        else
            ()
};


declare function config:get-fonts-dir() as xs:string? {
    let $repoDir := config:get-repo-dir()
    return
        if ($repoDir) then
            $repoDir || "/fonts"
        else
            ()
};

declare function config:distinct-values($values){
for $value in $values
   group by $value
   return
       $value
};