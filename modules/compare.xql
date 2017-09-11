xquery version "3.1" encoding "UTF-8";


module namespace compare = "https://www.betamasaheft.uni-hamburg.de/BetMas/compare";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace app = "https://www.betamasaheft.uni-hamburg.de/BetMas/app" at "app.xqm";
import module namespace item = "https://www.betamasaheft.uni-hamburg.de/BetMas/item" at "item.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMas/nav" at "nav.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMas/apprest" at "apprest.xqm";
import module namespace error = "https://www.betamasaheft.uni-hamburg.de/BetMas/error" at "error.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace console = "http://exist-db.org/xquery/console";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";
import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace kwic = "http://exist-db.org/xquery/kwic"
    at "resource:org/exist/xquery/lib/kwic.xql";
(: For interacting with the TEI document :)
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace dcterms = "http://purl.org/dc/terms";
declare namespace saws = "http://purl.org/saws/ontology";
declare namespace cmd = "http://www.clarin.eu/cmd/";

(: For REST annotations :)
declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";

declare variable $compare:meta := <meta  xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $genauthor in $config:repo-descriptor/repo:author
    return
        <meta xmlns="http://www.w3.org/1999/xhtml" name="creator" content="{$genauthor/text()}"></meta>
        ;


declare 
%rest:GET
%rest:path("/BetMas/compare")
%rest:query-param("workid", "{$workid}", "")
%output:method("html5")
function compare:compare(
$workid as xs:string*) {
let $console := console:log('got to rest comparison')
let $w := collection($config:data-rootW)//id($workid)


let $Cmap := map {'type':= 'item', 'name' := $workid, 'path' := base-uri($w)}

return
if(exists($w) or $workid ='') then (
<rest:response>
            <http:response
                status="200">
                <http:header
                    name="Content-Type"
                    value="text/html; charset=utf-8"/>
            </http:response>
        </rest:response>,
        <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <title property="dcterms:title og:title schema:name">Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</title>
        <link rel="shortcut icon" href="resources/images/favicon.ico"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
         {$compare:meta}
{apprest:scriptStyle()}
    </head>
    <body id="body">
       {nav:bar()}
        {nav:modals()}
        <div id="content">
        <div class="col-md-12">
        <form action="" class="form form-horizontal">
        <div class="form-group">
            <div class="input-group">
                <input placeholder="choose work to compare manuscripts" class="form-control" list="gotohits" id="GoTo" name="workid" data-value="works"/>
                <datalist id="gotohits">
                    
                </datalist>
                <div class="input-group-btn">
                    <button type="submit" class="btn btn-primary"> Compare
                </button>
                </div>
            </div>
        </div>
    </form>
        <div class="msscomp col-md-12">
            {apprest:compareMssFromForm($workid)}
        </div>
        </div>
        </div>
         {nav:footer()}

        <script type="text/javascript" src="resources/js/titles.js"/>
        <script type="text/javascript" src="resources/js/slickoptions.js"/>
    <script type="application/javascript" src="resources/js/coloronhover.js"/>
        <script type="text/javascript" src="resources/js/lookup.js"/>
       
    </body>
</html>
        )
        else (
        <rest:response>
            <http:response
                status="400">
                <http:header
                    name="Content-Type"
                    value="text/html; charset=utf-8"/>
            </http:response>
        </rest:response>,
        error:error($Cmap)
        )
};