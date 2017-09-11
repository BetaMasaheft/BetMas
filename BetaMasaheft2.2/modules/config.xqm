xquery version "3.0";


(:~
 : A set of helper functions to access the application context from
 : within a module.
 :)
module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config";

declare namespace templates="http://exist-db.org/xquery/templates";

declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";


declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace http = "http://expath.org/ns/http-client";


declare variable $config:appUrl := 'http://betamasaheft.eu';

declare variable $config:response200 := <rest:response>
        <http:response
            status="200">
                
            <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"
                    />
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

declare variable $config:ppw := 'Hdt7.10';


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
declare variable $config:data-root := $config:app-root || "/data";
declare variable $config:schema-root := $config:app-root || "/schema";
declare variable $config:data-rootMS := $config:data-root || "/manuscripts";
declare variable $config:data-rootN := $config:data-root || "/narratives";
declare variable $config:data-rootW := $config:data-root || "/works";
declare variable $config:data-rootPl := $config:data-root || "/places";
declare variable $config:data-rootPr := $config:data-root || "/persons";
declare variable $config:data-rootIn := $config:data-root || "/institutions";
declare variable $config:data-rootA := $config:data-root || "/authority-files";

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