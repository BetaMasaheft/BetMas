xquery version "3.1" encoding "UTF-8";
(:~
 : module for the different item views, decides what kind of item it is, in which way to display it
 :
 : @author Pietro Liuzzo 
 :)
module namespace restItem = "https://www.betamasaheft.uni-hamburg.de/BetMas/restItem";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace log="http://www.betamasaheft.eu/log" at "log.xqm";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMas/switch2"  at "xmldb:exist:///db/apps/BetMas/modules/switch2.xqm";
import module namespace tl="https://www.betamasaheft.uni-hamburg.de/BetMas/timeline"at "xmldb:exist:///db/apps/BetMas/modules/timeline.xqm";
import module namespace item2 = "https://www.betamasaheft.uni-hamburg.de/BetMas/item2" at "xmldb:exist:///db/apps/BetMas/modules/item.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMas/nav" at "xmldb:exist:///db/apps/BetMas/modules/nav.xqm";
import module namespace error = "https://www.betamasaheft.uni-hamburg.de/BetMas/error" at "xmldb:exist:///db/apps/BetMas/modules/error.xqm";
import module namespace editors="https://www.betamasaheft.uni-hamburg.de/BetMas/editors" at "xmldb:exist:///db/apps/BetMas/modules/editors.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMas/apprest" at "xmldb:exist:///db/apps/BetMas/modules/apprest.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace charts = "https://www.betamasaheft.uni-hamburg.de/BetMas/charts" at "xmldb:exist:///db/apps/BetMas/modules/charts.xqm";
import module namespace LitFlow = "https://www.betamasaheft.uni-hamburg.de/BetMas/LitFlow" at "xmldb:exist:///db/apps/BetMas/modules/LitFlow.xqm";
import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace kwic = "http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMas/string" at "xmldb:exist:///db/apps/BetMas/modules/tei2string.xqm";
import module namespace dtsc="https://www.betamasaheft.uni-hamburg.de/BetMas/dtsc" at "xmldb:exist:///db/apps/BetMas/modules/dtsclient.xqm";
(: For interacting with the TEI document :)
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace dcterms = "http://purl.org/dc/terms";
declare namespace saws = "http://purl.org/saws/ontology";
declare namespace cmd = "http://www.clarin.eu/cmd/";

(: For REST annotations :)
declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";

declare variable $restItem:deleted := doc('/db/apps/BetMas/lists/deleted.xml');

(:parameter hi is used to highlight searched word when coming query from Dillmann
parameters start and perpage are for the text visualization with pagination as per standard usage:)
declare
%rest:GET
%rest:path("/BetMas/{$id}/main")
%rest:query-param("start", "{$start}", "")
%rest:query-param("end", "{$end}", "")
%rest:query-param("ref", "{$ref}", "")
%rest:query-param("edition", "{$edition}", "")
%rest:query-param("hi", "{$hi}", '')
%rest:query-param("per-page", "{$per-page}", "")
%output:method("html5")
function restItem:getItem(
$id as xs:string*,
$start as xs:string*,
$end as xs:string*,
$ref as xs:string*,
$edition as xs:string*,
$per-page as xs:string*,
$hi as xs:string*) {
  let $item := $apprest:collection-root/id($id)[name() eq 'TEI']
  let $col := switch2:col($item/@type)
  let $log := log:add-log-message('/'||$id||'/main', sm:id()//sm:real/sm:username/string() , 'item')
  return
restItem:ITEM('main', $id, $col,$start,
$end,
$ref,
$edition,$per-page, $hi)
};

declare
%rest:GET
%rest:path("/BetMas/{$collection}/{$id}/main")
%rest:query-param("start", "{$start}", "")
%rest:query-param("end", "{$end}", "")
%rest:query-param("ref", "{$ref}", "")
%rest:query-param("edition", "{$edition}", "")
%rest:query-param("hi", "{$hi}", '')
%rest:query-param("per-page", "{$per-page}", "")
%rest:query-param("hi", "{$hi}", '')
%output:method("html5")
function restItem:getItemC(
$collection as xs:string*,
$id as xs:string*,
$start as xs:string*,
$end as xs:string*,
$ref as xs:string*,
$edition as xs:string*,
$per-page as xs:string*,
$hi as xs:string*) {
  let $log := log:add-log-message('/'||$collection||'/'||$id||'/main', sm:id()//sm:real/sm:username/string() , 'item')
  return
restItem:ITEM('main', $id, $collection,$start,
$end,
$ref,
$edition,$per-page, $hi)
};


declare
%rest:GET
%rest:path("/BetMas/{$collection}/{$id}/geoBrowser")
%rest:query-param("start", "{$start}", "")
%rest:query-param("end", "{$end}", "")
%rest:query-param("ref", "{$ref}", "")
%rest:query-param("edition", "{$edition}", "")
%rest:query-param("hi", "{$hi}", '')
%rest:query-param("per-page", "{$per-page}", "")
%rest:query-param("hi", "{$hi}", '')
%output:method("html5")
function restItem:getgeoBrowser(
$collection as xs:string*,
$id as xs:string*,
$start as xs:string*,
$end as xs:string*,
$ref as xs:string*,
$edition as xs:string*,
$per-page as xs:string*,
$hi as xs:string*) {
let $log := log:add-log-message('/'||$collection||'/'||$id||'/geoBrowser', sm:id()//sm:real/sm:username/string() , 'item')
  return
restItem:ITEM('geobrowser', $id, $collection,$start,
$end,
$ref,
$edition,$per-page, $hi)
};


declare
%rest:GET
%rest:path("/BetMas/{$collection}/{$id}/text")
%rest:query-param("start", "{$start}", "")
%rest:query-param("end", "{$end}", "")
%rest:query-param("ref", "{$ref}", "")
%rest:query-param("edition", "{$edition}", "")
%rest:query-param("hi", "{$hi}", '')
%rest:query-param("per-page", "{$per-page}", "")
%output:method("html5")
function restItem:gettext(
$collection as xs:string*,
$id as xs:string*,
$start as xs:string*,
$end as xs:string*,
$ref as xs:string*,
$edition as xs:string*,
$per-page as xs:string*,
$hi as xs:string*) {
let $log := log:add-log-message('/'||$collection||'/'||$id||'/text', sm:id()//sm:real/sm:username/string() , 'item')
  return
restItem:ITEM('text', $id, $collection,$start,
$end,
$ref,
$edition,$per-page, $hi)
};


declare
%rest:GET
%rest:path("/BetMas/{$collection}/{$id}/analytic")
%rest:query-param("start", "{$start}", "")
%rest:query-param("end", "{$end}", "")
%rest:query-param("ref", "{$ref}", "")
%rest:query-param("edition", "{$edition}", "")
%rest:query-param("hi", "{$hi}", '')
%rest:query-param("per-page", "{$per-page}", "")
%rest:query-param("hi", "{$hi}", '')
%output:method("html5")
function restItem:getanalytic(
$collection as xs:string*,
$id as xs:string*,
$start as xs:string*,
$end as xs:string*,
$ref as xs:string*,
$edition as xs:string*,
$per-page as xs:string*,
$hi as xs:string*) {
let $log := log:add-log-message('/'||$collection||'/'||$id||'/analytic', sm:id()//sm:real/sm:username/string() , 'item')
  return
restItem:ITEM('analytic', $id, $collection,$start,
$end,
$ref,
$edition,$per-page, $hi)
};


declare
%rest:GET
%rest:path("/BetMas/{$collection}/{$id}/graph")
%rest:query-param("start", "{$start}", "")
%rest:query-param("end", "{$end}", "")
%rest:query-param("ref", "{$ref}", "")
%rest:query-param("edition", "{$edition}", "")
%rest:query-param("hi", "{$hi}", '')
%rest:query-param("per-page", "{$per-page}", "")
%rest:query-param("hi", "{$hi}", '')
%output:method("html5")
function restItem:getgraph(
$collection as xs:string*,
$id as xs:string*,
$start as xs:string*,
$end as xs:string*,
$ref as xs:string*,
$edition as xs:string*,
$per-page as xs:string*,
$hi as xs:string*) {
restItem:ITEM('graph', $id, $collection,$start,
$end,
$ref,
$edition,$per-page, $hi)
};



declare
%rest:GET
%rest:path("/BetMas/{$id}/corpus")
%rest:query-param("start", "{$start}", "")
%rest:query-param("end", "{$end}", "")
%rest:query-param("ref", "{$ref}", "")
%rest:query-param("edition", "{$edition}", "")
%rest:query-param("hi", "{$hi}", '')
%rest:query-param("per-page", "{$per-page}", "")
%rest:query-param("hi", "{$hi}", '')
%output:method("html5")
function restItem:getcorpus(
$id as xs:string*,
$start as xs:string*,
$end as xs:string*,
$ref as xs:string*,
$edition as xs:string*,
$per-page as xs:string*,
$hi as xs:string*) {
let $log := log:add-log-message('/corpus/'||$id, sm:id()//sm:real/sm:username/string() , 'item')
  return
restItem:ITEM('corpus', $id, 'corpora', $start,
$end,
$ref,
$edition,$per-page, $hi)
};


declare function restItem:ITEM($type, $id, $collection,
$start,
$end,
$ref,
$edition,
$per-page,
$hi as xs:string*){
let $collect := switch2:collectionVar($collection)
let $coll := $config:data-root || '/' || $collection
let $this := $collect/id($id)[name()='TEI']
let $biblio :=
<bibl>
{
for $author in config:distinct-values(($this//t:revisionDesc/t:change/@who| $this//t:editor/@key))
                return
<author>{editors:editorKey(string($author))}</author>
}
{let $time := max($this//t:revisionDesc/t:change/xs:date(@when))
return
<date type="lastModified">{format-date($time, '[D].[M].[Y]')}</date>
}
<idno type="url">
{($config:appUrl ||'/'|| $collection||'/' ||$id)}
</idno>

<idno type="DOI">
{('DOI:'||$config:DOI || '.' ||$id)}
</idno>
<coll>{$collection}</coll>
</bibl>
let $Cmap := map {'type': 'collection', 'name' : $collection, 'path' : $coll}
let $Imap := map {'type': 'item', 'name' : $id, 'path' : $collection}
return


if(xdb:collection-available($coll)) then (
(:check that it is one of our collections:)
 if ($collection='institutions') then (
 (:controller should handle this by redirecting /institutions/ID/main to /manuscripts/ID/list which is then taken care of by list.xql:)
 ) else
(:check if the item has been deleted:)
if( $restItem:deleted//t:item[. eq $id]) then
(let $formerlyListed := $apprest:collection-root//t:relation[@name eq 'betmas:formerlyAlsoListedAs'][@passive eq $id]
return
if(count($formerlyListed) = 1) then 
(:redirect to record containing formerly listed as:)
<rest:response>
 <http:response
                status="301">
                 <http:header
                    name="Location"
                    value="/{string($formerlyListed/@active)}"/>
                 <http:header
                    name="Connection"
                    value="close"/>
  </http:response>
</rest:response>
else 
<rest:response>
            <http:response
                status="410">
                <http:header
                    name="Content-Type"
                    value="text/html; charset=utf-8"/>
            </http:response>
        </rest:response>,
        <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
        <title>Not here any more... 410 - Gone</title></head>
        <body>
        <p>Sorry! {$id} has been marked as deleted.</p>
        <p>You can check the list of <a href="/deleted.html">all deleted records here </a></p></body>
        </html>
        )
(:        check if there is more then one:)
         else   if(count($this) gt 1) then 
         (
<rest:response>
            <http:response
                status="409">
                <http:header
                    name="Content-Type"
                    value="text/html; charset=utf-8"/>
            </http:response>
        </rest:response>,
        <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
        <title>More than one {$id}</title></head>
        <body><p>Something has gone wrong and there are more than one item with id {$id}.</p>
        <ul>
        {for $i in $this
        return <li>{base-uri($i)}</li>}
        </ul>
        </body>
        </html>
        )
        (:        check that the item exists :)
    else   if(count($this) = 1) then (
<rest:response>
            <http:response
                status="200">
                <http:header
                    name="Content-Type"
                    value="text/html; charset=utf-8"/>
            </http:response>
        </rest:response>,
       <html xmlns="http://www.w3.org/1999/xhtml" version="XHTML+RDFa 1.1">
    <head>
       <!-- Global site tag (gtag.js) - Google Analytics -->
        <script async="async" src="https://www.googletagmanager.com/gtag/js?id=UA-106148968-1"></script>
     
    {apprest:app-title($id)}
        <link rel="alternate" type="application/rdf+xml"
          title="RDF Representation"
          href="https://betamasaheft.eu/rdf/{$collection}/{$id}.rdf" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        {apprest:app-meta($biblio)}
        {apprest:scriptStyle()}
        {if($type='text') then () else apprest:ItemScriptStyle()}
        {if($type='graph') then (
                         <script src="https://d3js.org/d3.v5.min.js"/>,
                         <script src="resources/js/d3sparql.js"/>) else ()}
            {if($type='text') then ( 
(:           mirador  manuscripts viewer under the text view for editions:)
         <style type="text/css">{'
                #viewer {{
                display: block;
                width: 100%;
                height: 600px;
                margin: 1em 5%;
                position: relative;
                }}'}
            </style>,
        <link rel="stylesheet" type="text/css" href="resources/mirador/css/mirador-combined.css"/>,
            <script src="resources/mirador/mirador.js"></script>) else ()}
    </head>
    <body id="body">
        {nav:barNew()}
        {nav:modalsNew()}
         <div id="content" class="w3-container w3-padding-48">
         {item2:RestViewOptions($this, $collection)}
  { item2:RestItemHeader($this, $collection)}
 

  {if ($type='corpus') then () else item2:RestNav($this, $collection, $type)}
  
<div id="main" class="w3-main alpheios-enabled">
{if ($type='corpus') then () else attribute style {'margin-left:10%'}}
   {switch($type)
   case 'corpus' return (
   <div class="w3-container">
   <label class="switch diplomaticHighlight">
  <input type="checkbox" class="w3-check"/>
  <div class="slider round" data-toggle="tooltip" title="Highlight diplomatic disourse interpretation"></div>
</label>
   {
   for $document in $apprest:collection-rootMS//t:relation[contains(@passive, $id)]
let $rootid := string($document/@active)
let $itemid :=substring-after($rootid, '#')
let $msid :=substring-before($rootid, '#')
return
<div class="w3-row documentcorpus w3-panel w3-leftbar">
{
let $doc := $document/ancestor::t:TEI//id($itemid)
return
(
<div class="w3-col" style="width:15%">
<a href="/{$msid}" class="MainTitle" data-value="{$msid}">{$msid}</a><br/>
     <a href="/{$rootid}">{if($doc/t:title) then string:additionstitles($doc/t:title/node()) else if($doc/t:desc/@type) then string($doc/t:desc/@type) else $itemid}</a>
    ({string:additionstitles($doc/t:locus)})
     
     </div>,
<div class="w3-rest">{
transform:transform(
        $doc,

        'xmldb:exist:///db/apps/BetMas/xslt/documents.xsl'
        ,
        ()
    )}</div>
    )
}
</div>
   }</div>
   )
   case 'geobrowser' return (
   <div class="w3-container">
   <div class="w3-container alert alert-info">You can download the <a href="https://betamasaheft.eu/api/KML/places/{$id}">KML</a> file visualized below in the <a href="https://geobrowser.de.dariah.eu">Dariah-DE Geobrowser</a>.</div>
   <h3>Map and timeline of places attestations marked up in the text.</h3>
   <iframe style="width: 100%; height: 800px;" id="geobrowserMap" src="https://geobrowser.de.dariah.eu/embed/index.html?kml1=https://betamasaheft.eu/api/KML/places/{$id}"/>
   </div>
   )
   case 'analytic' return (
   <div class="w3-container" >
             <img id="loading" src="resources/Loading.gif" style="display: none;"></img>
            <div class="w3-container"><div id="BetMasRel" class="w3-half w3-padding"  style="display: none;">


                <div class="input-group container">
                    <button id="clusterOutliers" class="w3-button w3-gray">Cluster outliers</button>
                    <button id="clusterByHubsize" class="w3-button w3-gray">Cluster by hubsize</button>
                </div>
                <div id="BetMasRelView" class="w3-container" data-value="{$id}"/>
                <script type="text/javascript"src="resources/js/visgraphspec.js"/>
            </div>
            <div class="container w3-half w3-padding">
                  {apprest:EntityRelsTable($this, $collection)}
            </div>
            </div>
            <div class="w3-container">
            <div class="w3-half w3-padding">
            <div id="timeLine" class="w3-container"/>
                <script type="text/javascript">
            {(:tl:RestEntityTimeLine($this, $collection):)''}
            </script>
            </div>
            <div class="w3-half w3-padding">
            {item2:RestPersRole($this, $collection)}
            </div>
            </div>

        </div>
   )
   case 'text' return (
   
   
   <div class="w3-container">
  <div class="w3-twothird" id="dtstext">{ if($this//t:div[@type eq 'edition'])
   then dtsc:text($id, $edition, $ref, $start, $end, $collection) else <p>No text available here.</p>}</div>
   <div class="w3-third w3-gray w3-padding">{item2:textBibl($this, $id)}</div>
   </div>
    ,
   for $contains in $this//t:relation[@name eq "saws:contains"]/@passive 
     let $ids:=  if(contains($contains, ' ')) then for $x in tokenize($contains, ' ') return $x else string($contains)
     for $contained in $ids
    let $cfile := $apprest:collection-rootW//id($contained)[self::t:TEI]
   return 
   
   <div class="w3-container">
   {<div class="w3-twothird" id="dtstext">Contains  {item2:title($contained)}
   {if ($cfile//t:div[@type eq 'edition']) 
   then dtsc:text($contained, '', '', '', '', 'works') else ()}</div>,
  <div class="w3-third w3-gray w3-padding">{item2:textBibl($this, $id)}</div>
   }</div>
 
   )
   case 'graph' return (
   switch($collection)
case 'manuscripts' return
let $ex :=  $this//t:msDesc/t:physDesc//t:extent/t:measure[@unit eq 'leaf'][not(@type eq 'blank')]/text()
return
<div class="w3-container" >
<button id="enrichTable" class="w3-button w3-red" disabled="disabled">Enrich Table</button>
<div class="alert alert-info" id="graphloadingstatus">Loading graph and synoptique table...</div>
   <div class="w3-container">
   <div class="w3-responsive">
   <table class="w3-table w3-bordered w3-hoverable w3-condensed" id="SdCTable" data-id="{$id}" data-extent="{$ex}">
   {if($this//t:msDesc/t:msIdentifier/t:idno[@facs]) then (attribute data-images{string($this//t:msDesc/t:msIdentifier/t:idno/@facs)}, attribute data-imagesSource{$this//t:msDesc/t:msIdentifier/t:collection/text()} )else ()}
            <thead>
                <tr>
                    <th>Quires</th>
                    <th>folios</th>
                    <th>UniMat</th>
                    <th>UniMarq</th>
                    <th>UniCah</th>
                    <th>UniCont</th>
                    <th>addition</th>
                    <th>UniMain</th>
                    <th>UniEcri</th>
                    <th>UniRegl</th>
                    <th>UniMep</th>
                    <th>decoration</th>
                    <th>UniProd</th>
                </tr>
            </thead>
            <tbody></tbody>
        </table>
        <script type="text/javascript" src="resources/js/SdCtable.js"></script></div>
        </div>
  <div id="graph" data-id="{$id}"/>
  <div class="w3-container">
    <div class="w3-container">
    <div class="w3-panel w3-red">
    <p class="w3-panel w3-red">
      Sankey diagram of the manuscript. Showing UniProd
      and UniCirc explicitly related. Transformations are given weight 1.
      UniProd and UniCirc declarations are given weight 2. Exact matches are given weight 3.
    There is no chronological implication.</p>
    </div>
      {charts:mssSankey($id)}
  </div>
    <div class="w3-container">
    <div class="w3-panel w3-red">
      <p>
      Graph of the manuscript transformations using the Syntaxe du Codex ontology.</p></div>
        <div class="w3-container" id="SdCGraph"/>
    </div>
  </div>
<!--  <div class="w3-container">
     <div id="GraphResult"/>
 </div> -->
   <script type="text/javascript"  src="resources/js/d3sparqlsettingsManuscripts.js"></script>
  </div>
   case 'places' return <div class="w3-container">{charts:pieAttestations($id, 'placeName')}</div>
  case 'persons' return
  <div class="w3-container" >
  <div id="graph" data-id="{$id}"/>
  <div class="w3-container" id="SNAPGraph"/>
  <p>Graph view of the SNAP relations between persons.</p>

  <div class="w3-container" id="AttestationsInWorks"/>
  <p>Annotated attestations in texts (works and manuscripts).</p>

   <script type="text/javascript"  src="resources/js/SNAPGraph.js"></script>
  <div class="w3-container">{charts:pieAttestations($id, 'persName')}</div>
   </div>
   case 'authority-files' return
let $Subjects := doc(concat($config:data-rootA, '/taxonomy.xml'))//t:category[t:desc='Subjects']//t:category/t:catDesc/text()
return
if ($id = $Subjects) then  (try{LitFlow:Sankey($id, 'works')} catch * {$err:description}, 
       try{LitFlow:Sankey($id, 'mss')} catch * {$err:description}) 
       else ()
   default return
   <div class="w3-container" >
   <div id="graph" data-id="{$id}" data-rdf="/api/RDFJSON/{$collection}/{$id}"/>
   <div id="mouseovervalue"><p class="w3-large MainTitle"></p></div>
  <div class="w3-container" id="GraphResultNotMS"/>
  <script src="resources/js/colorbrewer.js"></script>
  <script type="text/javascript"  src="resources/js/d3sparqlsettingsITEM.js"></script>
  </div>
   )
   default return
(:   THE MAIN VIEW :)
  (if($collection='places') then (
  <div class="w3-container" >
  <div 
    class="w3-half w3-padding" ><div id="entitymap" style="height: 400px"/></div>
<div 
    class="w3-half w3-padding" >   <iframe
   style="border:none;"
                allowfullscreen="true"
                width="100%" 
                height="400" 
                src="https://peripleo.pelagios.org/embed/{encode-for-uri(concat('http://betamasaheft.eu/places/',$id))}">
            </iframe>
            </div>
   </div>,
   <script>{'var placeid = "'||$id||'"'}</script>,
            <script  type="text/javascript" src="resources/geo/geojsonentitymap.js"></script>) else (),

   <div  class="alpheios-enabled">{item2:RestItem($this, $collection)}</div>,
   
        
(:   apprest:namedentitiescorresps($this, $collection),:)
(:   the form with a list of potental relation keywords to find related items. value is used by Jquery to query rest again on api:SharedKeyword($keyword) :)
   switch($collection)
   case 'works' return  (
   item2:RestMiniatures($id))
  case 'persons' return (item2:RestPersRole($this, $collection), item2:RestTabot($id), item2:RestAdditions($id), item2:RestMiniatures($id))
    case 'authority-files' return
    if (starts-with($id, 'AT')) then 
  <div class="w3-container">
    <h4>Art Objects associated with this Art Theme in miniatures and other manuscript decorations</h4>
    <div  class="w3-panel w3-red">{item2:RestMiniaturesKeys($id)}</div>
   <div  class="w3-panel w3-red">{item2:RestMiniatures($id)}</div>
</div>
else ()
   case  'institutions' return (<div 
    class="w3-container" >   <iframe
   style="border:none;"
                allowfullscreen="true"
                width="100%" 
                height="400" 
                src="https://peripleo.pelagios.org/embed/{encode-for-uri(concat('http://betamasaheft.eu/places/',$id))}">
            </iframe>
            </div>,<div id="entitymap" style="width: 100%; height: 400px"/>,
   <script>{'var placeid = "'||$id||'"'}</script>,
            <script  type="text/javascript" src="resources/geo/geojsonentitymap.js"></script>
            )
   default return ()
   )
   }
   <div class="w3-container w3-margin-bottom">
   <div class="w3-container w3-padding w3-black w3-card-4 ">This page contains RDFa. 
   <a href="/rdf/{$collection}/{$id}.rdf">RDF+XML</a> graph of this resource. Alternate representations available via <a href="/api/void/{$id}">VoID</a>.</div>
   <div class="w3-container w3-padding w3-card-4 " id="permanentIDs{$id}" style="max-heigh:400px;overflow:auto"
   data-path="{restItem:capitalize-first(substring-after(base-uri($this), '/db/apps/BetMasData/'))}" 
   data-id="{$id}" data-type="{restItem:capitalize-first($collection)}"><a class="w3-btn w3-gray" id="LoadPermanentIDs{$id}">Permalinks</a></div>
   <script  type="text/javascript" src="resources/js/permanentID.js"></script>
   
   </div>
  { apprest:authors($this, $collection)}
   </div>


</div>

        {nav:footerNew()}

       {apprest:ItemFooterScript()}

    </body>
</html>
        )
         
        else
(:        error message if item does not exist:)
       (<rest:response>
            <http:response
                status="400">
                <http:header
                    name="Content-Type"
                    value="text/html; charset=utf-8"/>
            </http:response>
        </rest:response>,
        error:error($Imap)
      )

        )
        else
(:        error message if the collection does not exist:)
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

declare function restItem:capitalize-first
  ( $arg as xs:string? )  as xs:string? {

   concat(upper-case(substring($arg,1,1)),
             substring($arg,2))
 } ;
