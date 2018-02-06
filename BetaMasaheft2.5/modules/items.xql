xquery version "3.1" encoding "UTF-8";
(:~
 : module for the different item views, decides what kind of item it is, in which way to display it
 : 
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)
module namespace restItem = "https://www.betamasaheft.uni-hamburg.de/BetMas/restItem";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace log="http://www.betamasaheft.eu/log" at "log.xqm";
import module namespace tl="https://www.betamasaheft.uni-hamburg.de/BetMas/timeline"at "timeline.xqm";
import module namespace app = "https://www.betamasaheft.uni-hamburg.de/BetMas/app" at "app.xqm";
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
declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";


(:parameter hi is used to highlight searched word when coming query from Dillmann
parameters start and perpage are for the text visualization with pagination as per standard usage:)
declare 
%rest:GET
%rest:path("/BetMas/{$id}/main")
%rest:query-param("start", "{$start}", 1)
%rest:query-param("per-page", "{$per-page}", 1)
%rest:query-param("hi", "{$hi}", '')
%output:method("html5")
function restItem:getItem(  
$id as xs:string*,
$start as xs:integer*, 
$per-page as xs:integer*, 
$hi as xs:string*) {
  let $item := collection($config:data-root)//id($id)[name()='TEI']
  let $col := app:switchcol($item/@type)
  let $log := log:add-log-message('/'||$id||'/main', xmldb:get-current-user(), 'item')
  return
restItem:ITEM('main', $id, $col,$start,$per-page, $hi)
};

declare 
%rest:GET
%rest:path("/BetMas/{$collection}/{$id}/main")
%rest:query-param("start", "{$start}", 1)
%rest:query-param("per-page", "{$per-page}", 1)
%rest:query-param("hi", "{$hi}", '')
%output:method("html5")
function restItem:getItem(
$collection as xs:string*,  
$id as xs:string*,
$start as xs:integer*, 
$per-page as xs:integer*, 
$hi as xs:string*) {
  let $log := log:add-log-message('/'||$collection||'/'||$id||'/main', xmldb:get-current-user(), 'item')
  return
restItem:ITEM('main', $id, $collection,$start,$per-page, $hi)
};

declare 
%rest:GET
%rest:path("/BetMas/{$collection}/{$id}/text")
%rest:query-param("start", "{$start}", 1)
%rest:query-param("per-page", "{$per-page}", 1)
%rest:query-param("hi", "{$hi}", '')
%output:method("html5")
function restItem:gettext(
$collection as xs:string*,  
$id as xs:string*,
$start as xs:integer*, 
$per-page as xs:integer*, 
$hi as xs:string*) {
let $log := log:add-log-message('/'||$collection||'/'||$id||'/text', xmldb:get-current-user(), 'item')
  return
restItem:ITEM('text', $id, $collection,$start,$per-page, $hi)
};


declare 
%rest:GET
%rest:path("/BetMas/{$collection}/{$id}/analytic")
%rest:query-param("start", "{$start}", 1)
%rest:query-param("per-page", "{$per-page}", 1)
%rest:query-param("hi", "{$hi}", '')
%output:method("html5")
function restItem:getanalytic(
$collection as xs:string*,  
$id as xs:string*,
$start as xs:integer*, 
$per-page as xs:integer*, 
$hi as xs:string*) {
let $log := log:add-log-message('/'||$collection||'/'||$id||'/analytic', xmldb:get-current-user(), 'item')
  return
restItem:ITEM('analytic', $id, $collection,$start,$per-page, $hi)
};




declare function restItem:ITEM($type, $id, $collection,
$start as xs:integer*, 
$per-page as xs:integer*, 
$hi as xs:string*){

let $c := '/db/apps/BetMas/data/' || $collection
let $this := collection($c)//id($id)
let $biblio :=
<bibl>
{
for $author in distinct-values($this//t:revisionDesc/t:change/@who)
                return
<author>{app:editorKey(string($author))}</author>
}
{let $time := max($this//t:revisionDesc/t:change/xs:date(@when))
return
<date type="lastModified">{format-date($time, '[D].[M].[Y]')}</date>
}
<idno type="url">
{($config:appUrl ||'/'|| $collection||'/' ||$id)}
</idno>
<coll>{$collection}</coll>
</bibl>
let $Cmap := map {'type':= 'collection', 'name' := $collection, 'path' := $c}
let $Imap := map {'type':= 'item', 'name' := $id, 'path' := $collection}
return 


if(xdb:collection-available($c)) then (
(:check that it is one of our collections:)
 if ($collection='institutions') then (
 (:controller should handle this by redirecting /institutions/ID/main to /manuscripts/ID/list which is then taken care of by list.xql:)
 )
        else
(:        check that the item exists:)
       if(collection($config:data-root)//id($id)[name() = 'TEI']) then (
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
    {apprest:app-title($id)}
        <link rel="shortcut icon" href="resources/images/favicon.ico"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        {apprest:app-meta($biblio)}
        {apprest:scriptStyle()}
        {apprest:ItemScriptStyle()}
    </head>
    <body id="body">
        {nav:bar()}
        {nav:modals()}
          {nav:searchhelp()}
         {item:RestViewOptions($this, $collection)}
  { item:RestItemHeader($this, $collection)}
 <div id="content" class="container-fluid col-md-12">
 
  { item:RestNav($this, $collection, $type)}
  
   {switch($type) 
   case 'analytic' return (
   <div class="container col-md-10">
             <img id="loading" src="resources/Loading.gif" style="display: none;"></img>   
            <div class="col-md-12"><div id="BetMasRel" class="container-fluid col-md-6"  style="display: none;">
            
     
                <div class="input-group container">
                    <button id="clusterOutliers" class="btn btn-secondary">Cluster outliers</button>
                    <button id="clusterByHubsize" class="btn btn-secondary">Cluster by hubsize</button>
                </div>
                <div id="BetMasRelView" class="col-md-12" data-value="{$id}"/>
                <script type="text/javascript"src="resources/js/visgraphspec.js"/>
            </div>
            <div class="container col-md-6">
                  {apprest:EntityRelsTable($this, $collection)}
            </div>
            </div>
            <div class="col-md-6">
            <div id="timeLine" class="col-md-12"/>
                <script type="text/javascript">
            {tl:RestEntityTimeLine($this, $collection)}
            </script>
            </div>
            <div class="col-md-6">
            {item:RestPersRole($this, $collection)}
            </div>
        </div>
   )
   case 'text' return item:RestText($this, $start, $per-page) 
   default return 
(:   THE MAIN VIEW :)
   (if($collection='places') then (<div id="entitymap" class="col-md-10" style="height: 400px"/>,
   <script>{'var placeid = "'||$id||'"'}</script>,
            <script  type="text/javascript" src="resources/geo/geojsonentitymap.js"></script>) else (),
   
   item:RestItem($this, $collection),
   apprest:namedentitiescorresps($this, $collection),
(:   the form with a list of potental relation keywords to find related items. value is used by Jquery to query rest again on api:SharedKeyword($keyword) :)
   switch($collection)
   case 'works' return  (item:RestMiniatures($id), <div><h3>Map and timeline of places attestations marked up in the text.</h3><iframe style="width: 100%; height: 800px;" id="geobrowserMap" src="http://geobrowser.de.dariah.eu/embed/index.html?kml1=http://betamasaheft.aai.uni-hamburg.de/api/KML/places/{$id}"/></div>)
   case 'persons' return (item:RestTabot($id), item:RestAdditions($id), item:RestMiniatures($id))
    case 'authority-files' return 
    <div class="col-md-12"><h4>Art Objects associated with this Art Theme in miniatures and other manuscript decorations</h4>

<div  class="alert alert-info">
{item:RestMiniaturesKeys($id)}
</div>

<div  class="well">
{item:RestMiniatures($id)}</div>
</div>
    case  'institutions' return (<div id="entitymap" style="width: 100%; height: 400px"/>,
   <script>{'var placeid = "'||$id||'"'}</script>,
            <script  type="text/javascript" src="resources/geo/geojsonentitymap.js"></script>)
   default return ()
   )
   }
   { apprest:authors($this, $collection)}
 
 
</div>
        
        {nav:footer()}
       
       {apprest:ItemFooterScript()}
    
    </body>
</html>
        )
        else
       (<rest:response>
            <http:response
                status="400">
                <http:header
                    name="Content-Type"
                    value="text/html; charset=utf-8"/>
            </http:response>
        </rest:response>,
        error:error($Imap)) 
       
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
