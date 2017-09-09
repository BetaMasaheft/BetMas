xquery version "3.1" encoding "UTF-8";


module namespace list = "https://www.betamasaheft.uni-hamburg.de/BetMas/list";
import module namespace app = "https://www.betamasaheft.uni-hamburg.de/BetMas/app" at "app.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "titles.xqm";
import module namespace BetMasMap = "https://www.betamasaheft.uni-hamburg.de/BetMas/map" at "map.xqm";
import module namespace item = "https://www.betamasaheft.uni-hamburg.de/BetMas/item" at "item.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMas/nav" at "nav.xqm";
import module namespace error = "https://www.betamasaheft.uni-hamburg.de/BetMas/error" at "error.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMas/apprest" at "apprest.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace console = "http://exist-db.org/xquery/console";
import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace kwic = "http://exist-db.org/xquery/kwic"
    at "resource:org/exist/xquery/lib/kwic.xql";
    
(: For interacting with the TEI document :)
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace dcterms = "http://purl.org/dc/terms";
declare namespace saws = "http://purl.org/saws/ontology";
declare namespace cmd = "http://www.clarin.eu/cmd/";


(: For REST annotations :)
declare namespace rest = "http://exquery.org/ns/restxq";

declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";


declare 
%rest:GET
%rest:path("/BetMas/{$collection}/list")
%rest:query-param("start", "{$start}", 1)
%rest:query-param("keyword", "{$keyword}", "")
%rest:query-param("language", "{$language}", "")
%rest:query-param("prms", "{$prms}", "")
%rest:query-param("per-page", "{$per-page}", 20)
%rest:form-param("date-range", "{$date-range}", "")
%rest:query-param("min-hits", "{$min-hits}", 0)
%rest:query-param("max-pages", "{$max-pages}", 20)
%output:method("html5")
function list:getlist(
$collection as xs:string*, 
$start as xs:integer*, 
$per-page as xs:integer*, 
$min-hits as xs:integer*, 
$max-pages as xs:integer*, 
$date-range as xs:string*,
$keyword as xs:string*,
$language as xs:string*, 
$prms as xs:string*) {
let $c := '/db/apps/BetMas/data/' || $collection
let $Cmap := map {'type':= 'collection', 'name' := $collection, 'path' := $c}
let $parameters := map{'key':=$keyword,'lang':=$language,'date':=$date-range}
return 


if(xdb:collection-available($c)) then (
<rest:response>
            <http:response
                status="200">
                <http:header
                    name="Content-Type"
                    value="text/html; charset=utf-8"/>
            </http:response>
        </rest:response>,
        
        console:log('got to the list rest main function'),
        
       <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <title property="dcterms:title og:title schema:name">Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</title>
        <link rel="shortcut icon" href="resources/images/favicon.ico"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <meta>
        {apprest:app-meta()}</meta>
{apprest:scriptStyle()}
    </head>
    <body id="body">
        {nav:bar()}
        {nav:modals()}
        {nav:searchhelp()}
       
 <div id="content" class="container-fluid col-md-12">
 {if($collection = 'authority-files') then (
 <div class="col-md-12">
 <div class="col-md-2">
 {for $cat in doc($c||'/taxonomy.xml')//t:category[not(parent::t:category)]
 let $val := $cat/t:desc/text()
 return 
 <div class="row">
 <p class="lead" href="/{$collection}/{$val}">{$val}<span class="badge">{count($cat/t:category)}</span></p>
 <ul>{for $subcat in $cat/t:category
 let $subval := $subcat/t:catDesc/text()
 return
 if ($subval/t:category)
 
 then (
 
 <div class="row">
 <p class="lead" href="/{$collection}/{$subval}">{$subval}<span class="badge">{count($subcat/t:category)}</span></p>
 <ul>{
 for $subsubcat in $subcat/t:category
 let $subsubval := $subsubcat/t:catDesc/text()
 return
 <li><a href="/{$collection}/list?keyword={$subsubval}">{collection($config:data-rootA)//id($subsubval)//t:titleStmt/t:title/text()}</a></li>
 
 }
 </ul>
 </div>
 )
 else(
 <li><a href="/{$collection}/list?keyword={$subval}">{collection($config:data-rootA)//id($subval)//t:titleStmt/t:title/text()}</a></li>)
 }</ul>
 </div>}
 </div>
 <div class="col-md-10">
 {if($keyword = '') then (<p class="lead">Select an entry on the left to see all records where this occurs.</p>, <span class="pull-right">{app:nextID($collection)}</span>) else (let $res := 
 let $hits :=  for $resource in collection($config:data-root)/t:TEI[descendant::t:term[@key = $keyword] or descendant::t:desc[@type = $keyword] or descendant::t:place[@type = $keyword] or descendant::t:ab[@type = $keyword] or descendant::t:faith[@type = $keyword] or descendant::t:occupation[@type = $keyword]]
                         return $resource
   return 
                      map { 
                      'hits' := $hits,
                      'collection' := $collection
                      }
                      
   return
 <div class="col-md-12">
  <div> <span id="hit-count" class="lead">
   {'There are ' || count($res("hits")) || ' resources that contain the exact keyword: ' || $keyword}
   </span>
  <span class="pull-right">{app:nextID($collection)}</span>
   </div>
   <div>
    <table class="table table-hover table-responsive"><thead><tr><th>id</th><th>title</th><th>type</th></tr></thead><tbody>{for $h in $res("hits") return <tr><td>{string($h/@xml:id)}</td><td><a href="{string($h/@xml:id)}">{titles:printTitle($h)}</a></td><td>{string($h/@type)}</td></tr>}</tbody></table>
   </div>
                   </div>                 ) }
 </div>
 </div>
 ) else
        let $hits := apprest:listrest('collection', $collection, $parameters, $prms)
    return 
    (
   <div class="col-md-12">
   <span id="hit-count" class="lead">
   {'There are ' || count($hits("hits")) || ' records in this selection of ' || $collection }
   </span>
                   </div>
                   ,
    <div class="col-md-2">
    {apprest:searchFilter-rest($collection, $hits)}
    {if($collection = 'manuscripts') then (apprest:institutions(),apprest:catalogues()) else ()}
    </div>,
    <div class="col-md-10">
   <div class="hidden-md hidden-lg hidden-sm">
     <ul class="pagination" >
    {apprest:paginate-rest($hits, $parameters, $start, $per-page, 5, 21)}
    </ul>
                   </div>
                   <div class="hidden-xs">
                   <ul class="pagination" >
    {apprest:paginate-rest($hits, $parameters, $start, $per-page, 9, 21)}
    </ul>
                   </div>
    
    {app:table($hits, $start, $per-page)}
    
      <div class="hidden-xs">
                   <ul class="pagination" >
    {apprest:paginate-rest($hits, $parameters, $start, $per-page, 9, 21)}
    </ul>
                   </div>
    <div class="hidden-md hidden-lg hidden-sm">
                   
                   <ul class="pagination" >
    {apprest:paginate-rest($hits, $parameters, $start, $per-page, 9, 21)}
    </ul>
                </div>
        </div>)
        }
</div>
        
        {nav:footer()}
       
        <script type="text/javascript" src="resources/js/toogle.js"/>
        <script type="text/javascript" src="resources/js/titles.js"/>
        <script type="text/javascript" src="resources/js/clavisid.js"/>
        <script type="text/javascript" src="resources/js/datatable.js"/>
        <script type="text/javascript" src="resources/js/lookup.js"/>
        <script type="text/javascript" src="resources/js/NewBiblio.js"/>
    </body>
</html>
        
        )
        else 
        (
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







declare 
%rest:GET
%rest:path("/BetMas/manuscripts/{$repoID}/list")
%rest:query-param("start", "{$start}", 1)
%rest:query-param("keyword", "{$keyword}", "")
%rest:query-param("language", "{$language}", "")
%rest:query-param("prms", "{$prms}", "")
%rest:query-param("per-page", "{$per-page}", 20)
%rest:form-param("date-range", "{$date-range}", "")
%rest:query-param("min-hits", "{$min-hits}", 0)
%rest:query-param("max-pages", "{$max-pages}", 20)
%output:method("html5")
function list:getrepolist(
$repoID as xs:string*, 
$start as xs:integer*, 
$per-page as xs:integer*, 
$min-hits as xs:integer*, 
$max-pages as xs:integer*, 
$date-range as xs:string*,
$keyword as xs:string*,
$language as xs:string*, 
$prms as xs:string*) {

(:the file for that institution:)
let $repos := '/db/apps/BetMas/data/institutions/'
let $Cmap := map {'type':= 'repo', 'name' := $repoID, 'path' := $repos}
let $parameters := map{'key':=$keyword,'lang':=$language,'date':=$date-range}
let $file := collection($config:data-rootIn)//id($repoID)[name()='TEI']
return 


if($file) then (
console:log('manuscripts/' || $repoID || '/list reached the rest function for list of mss from one institution'),
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
        <meta>
        {apprest:app-meta()}</meta>
{apprest:scriptStyle()}
<link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/mapbox.css"/>
        <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/leaflet.css"/>
        <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/leaflet.fullscreen.css"/>
        <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/leaflet-search.css"/>
       <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="http://cdn.leafletjs.com/leaflet/v0.7.7/leaflet.js"/>
        <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="resources/js/mapbox.js"/>
        <script  xmlns="http://www.w3.org/1999/xhtml"type="text/javascript" src="resources/js/Leaflet.fullscreen.min.js"/>
        <script  xmlns="http://www.w3.org/1999/xhtml"type="text/javascript" src="resources/js/leaflet-search.js"/>
         
    </head>
    <body id="body">
        {nav:bar()}
        {nav:modals()}
        {nav:searchhelp()}
       <div class="col-md-4">
       {item:RestItem($file, 'institutions')}
       <div id="map" style="width: 100%; height: 400px"/>
            <script  type="text/javascript" >{BetMasMap:RestEntityMap($file, 'institutions')}</script>
       </div>
 <div id="content" class="container-fluid col-md-8">
 {let $hits := apprest:listrest('repo', $repoID, $parameters, $prms)
    return 
    (
   <div class="col-md-12">
   <span id="hit-count" class="lead">
   {'There are ' || count($hits("hits")) || ' manuscripts at ' || titles:printTitleID($repoID) }
   </span>
   {<a target="_blank" class="btn btn-info" href="/manuscripts/{$repoID}/list/viewer">Images available for this repository</a>}
                   </div>
                   ,
    <div class="col-md-2">
    {apprest:searchFilter-rest($repoID, $hits)}
    <a role="btn" class="btn btn-primary" href="/manuscripts/list">Back to full list</a>
    </div>,
    <div class="col-md-10">
   <div class="hidden-md hidden-lg hidden-sm">
     <ul class="pagination" >
    {apprest:paginate-rest($hits, $parameters, $start, $per-page, 5, 21)}
    </ul>
                   </div>
                   <div class="hidden-xs">
                   <ul class="pagination" >
    {apprest:paginate-rest($hits, $parameters, $start, $per-page, 9, 21)}
    </ul>
                   </div>
    
    {app:table($hits, $start, $per-page)}
    
      <div class="hidden-xs">
                   <ul class="pagination" >
    {apprest:paginate-rest($hits, $parameters, $start, $per-page, 9, 21)}
    </ul>
                   </div>
    <div class="hidden-md hidden-lg hidden-sm">
                   
                   <ul class="pagination" >
    {apprest:paginate-rest($hits, $parameters, $start, $per-page, 9, 21)}
    </ul>
                </div>
        </div>)
        }
</div>
        
        {nav:footer()}
       
        <script type="text/javascript" src="resources/js/toogle.js"/>
        <script type="text/javascript" src="resources/js/titles.js"/>
        <script type="text/javascript" src="resources/js/clavisid.js"/>
        <script type="text/javascript" src="resources/js/datatable.js"/>
        <script type="text/javascript" src="resources/js/lookup.js"/>
        <script type="text/javascript" src="resources/js/NewBiblio.js"/>
    </body>
</html>
        
        )
        else 
        (
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



declare 
%rest:GET
%rest:path("/BetMas/catalogues/list")
%output:method("html5")
function list:getcatalogues() {
(
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
        <meta>
        {apprest:app-meta()}</meta>
{apprest:scriptStyle()}
<link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/mapbox.css"/>
        <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/leaflet.css"/>
        <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/leaflet.fullscreen.css"/>
        <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/leaflet-search.css"/>
       <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="http://cdn.leafletjs.com/leaflet/v0.7.7/leaflet.js"/>
        <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="resources/js/mapbox.js"/>
        <script  xmlns="http://www.w3.org/1999/xhtml"type="text/javascript" src="resources/js/Leaflet.fullscreen.min.js"/>
        <script  xmlns="http://www.w3.org/1999/xhtml"type="text/javascript" src="resources/js/leaflet-search.js"/>
         
    </head>
    <body id="body">
        {nav:bar()}
        {nav:modals()}
        {nav:searchhelp()}
       <div class="col-md-12">
       
      <h1>Available catalogues</h1>
    <ul>
    {
   for $catalogue in distinct-values(collection($config:data-rootMS)//t:listBibl[@type='catalogue']//t:ptr/@target)
	let $xml-url := concat('https://api.zotero.org/groups/358366/items?&amp;tag=', $catalogue, '&amp;format=bib&amp;style=hiob-ludolf-centre-for-ethiopian-studies')
let $data := httpclient:get(xs:anyURI($xml-url), true(), <Headers/>)
order by $data
return
    <li class="lead">
    <a href="/catalogues/{$catalogue}/list">{$data}</a>
    </li>
    }
    </ul>
    <p>More catalogues will be processed. A list of the catalogues to be processed and of the work in progress can be seen <a href="https://github.com/SChAth/Manuscripts/wiki/List-of-manuscripts">here</a></p>
       
       
        </div>
        {nav:footer()}
    </body>
</html>
)
     
};

declare 
%rest:GET
%rest:path("/BetMas/catalogues/{$catalogueID}/list")
%rest:query-param("start", "{$start}", 1)
%rest:query-param("keyword", "{$keyword}", "")
%rest:query-param("language", "{$language}", "")
%rest:query-param("prms", "{$prms}", "")
%rest:query-param("per-page", "{$per-page}", 20)
%rest:form-param("date-range", "{$date-range}", "")
%rest:query-param("min-hits", "{$min-hits}", 0)
%rest:query-param("max-pages", "{$max-pages}", 20)
%output:method("html5")
function list:getcataloguelist(
$catalogueID as xs:string*, 
$start as xs:integer*, 
$per-page as xs:integer*, 
$min-hits as xs:integer*, 
$max-pages as xs:integer*, 
$date-range as xs:string*,
$keyword as xs:string*,
$language as xs:string*, 
$prms as xs:string*) {

(:the file for that institution:)
let $catalogues := for $catalogue in distinct-values(collection($config:data-rootMS)//t:listBibl[@type='catalogue']//t:ptr/@target)
	return $catalogue
let $Cmap := map {'type':= 'catalogue', 'name' := $catalogueID, 'path' := $catalogues}
let $parameters := map{'key':=$keyword,'lang':=$language,'date':=$date-range}
return 


if($catalogueID = $catalogues) then (
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
        <meta>
        {apprest:app-meta()}</meta>
{apprest:scriptStyle()}
<link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/mapbox.css"/>
        <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/leaflet.css"/>
        <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/leaflet.fullscreen.css"/>
        <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/leaflet-search.css"/>
       <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="http://cdn.leafletjs.com/leaflet/v0.7.7/leaflet.js"/>
        <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="resources/js/mapbox.js"/>
        <script  xmlns="http://www.w3.org/1999/xhtml"type="text/javascript" src="resources/js/Leaflet.fullscreen.min.js"/>
        <script  xmlns="http://www.w3.org/1999/xhtml"type="text/javascript" src="resources/js/leaflet-search.js"/>
         
    </head>
    <body id="body">
        {nav:bar()}
        {nav:modals()}
        {nav:searchhelp()}
       <div class="col-md-12">
       
      <h1>{let $xml-url := concat('https://api.zotero.org/groups/358366/items?&amp;tag=', $catalogueID, '&amp;format=bib&amp;style=hiob-ludolf-centre-for-ethiopian-studies')
let $data := httpclient:get(xs:anyURI($xml-url), true(), <Headers/>)
return $data
}</h1>
       
       <div id="content" class="col-md-12">
 {let $hits := apprest:listrest('catalogue',$catalogueID, $parameters, $prms)
    return 
    (
   <div class="col-md-12">
   <span id="hit-count" class="lead">
   {'This catalogue has been quoted in ' || count($hits("hits")) || ' manuscript records.' }
   </span>
                   </div>
                   ,
    <div class="col-md-2">
    {apprest:searchFilter-rest($catalogueID, $hits)}
    <a role="btn" class="btn btn-primary" href="/manuscripts/list">Back to full list</a>
    </div>,
    <div class="col-md-10">
   <div class="hidden-md hidden-lg hidden-sm">
     <ul class="pagination" >
    {apprest:paginate-rest($hits, $parameters, $start, $per-page, 5, 21)}
    </ul>
                   </div>
                   <div class="hidden-xs">
                   <ul class="pagination" >
    {apprest:paginate-rest($hits, $parameters, $start, $per-page, 9, 21)}
    </ul>
                   </div>
    
    {app:table($hits, $start, $per-page)}
    
      <div class="hidden-xs">
                   <ul class="pagination" >
    {apprest:paginate-rest($hits, $parameters, $start, $per-page, 9, 21)}
    </ul>
                   </div>
    <div class="hidden-md hidden-lg hidden-sm">
                   
                   <ul class="pagination" >
    {apprest:paginate-rest($hits, $parameters, $start, $per-page, 9, 21)}
    </ul>
                </div>
        </div>)
        }
</div>
 
        </div>
        {nav:footer()}
       
        <script type="text/javascript" src="resources/js/toogle.js"/>
        <script type="text/javascript" src="resources/js/titles.js"/>
        <script type="text/javascript" src="resources/js/clavisid.js"/>
        <script type="text/javascript" src="resources/js/datatable.js"/>
        <script type="text/javascript" src="resources/js/lookup.js"/>
        <script type="text/javascript" src="resources/js/NewBiblio.js"/>
    </body>
</html>
        
        )
        else 
        (
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
