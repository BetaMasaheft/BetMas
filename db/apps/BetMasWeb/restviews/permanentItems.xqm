xquery version "3.1" encoding "UTF-8";
(:~
 : module for the different item views, decides what kind of item it is, in which way to display it
 :
 : @author Pietro Liuzzo 
 :)
 
module namespace PermRestItem = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/PermRestItem";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/switch2"  at "xmldb:exist:///db/apps/BetMasWeb/modules/switch2.xqm";
import module namespace tl="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/timeline"at "xmldb:exist:///db/apps/BetMasWeb/modules/timeline.xqm";
import module namespace item2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/item2" at "xmldb:exist:///db/apps/BetMasWeb/modules/item.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/nav" at "xmldb:exist:///db/apps/BetMasWeb/modules/nav.xqm";
import module namespace error = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/error" at "xmldb:exist:///db/apps/BetMasWeb/modules/error.xqm";
import module namespace editors="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/editors" at "xmldb:exist:///db/apps/BetMasWeb/modules/editors.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/apprest" at "xmldb:exist:///db/apps/BetMasWeb/modules/apprest.xqm";
import module namespace scriptlinks = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/scriptlinks" at "xmldb:exist:///db/apps/BetMasWeb/modules/scriptlinks.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace charts = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/charts" at "xmldb:exist:///db/apps/BetMasWeb/modules/charts.xqm";
import module namespace LitFlow = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/LitFlow" at "xmldb:exist:///db/apps/BetMasWeb/modules/LitFlow.xqm";
import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace kwic = "http://exist-db.org/xquery/kwic"
    at "resource:org/exist/xquery/lib/kwic.xql";
import module namespace console="http://exist-db.org/xquery/console";
import module namespace dtsc="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/dtsc" at "xmldb:exist:///db/apps/BetMasWeb/modules/dtsclient.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/string" at "xmldb:exist:///db/apps/BetMasWeb/modules/tei2string.xqm";
import module namespace viewItem = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/viewItem" at "xmldb:exist:///db/apps/BetMasWeb/modules/viewItem.xqm";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";

(: For interacting with the TEI document :)
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace dcterms = "http://purl.org/dc/terms";
declare namespace saws = "http://purl.org/saws/ontology";
declare namespace cmd = "http://www.clarin.eu/cmd/";

(: For REST annotations :)
declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";

declare variable $PermRestItem:deleted := doc('/db/apps/lists/deleted.xml');


declare function PermRestItem:capitalize-first
  ( $arg as xs:string? )  as xs:string? {

   concat(upper-case(substring($arg,1,1)),
             substring($arg,2))
 } ;
 
(:parameter hi is used to highlight searched word when coming query from Dillmann
parameters start and perpage are for the text visualization with pagination as per standard usage:)
declare
%rest:GET
%rest:path("/BetMasWeb/permanent/{$sha}/{$id}/main")
%rest:query-param("start", "{$start}", 1)
%rest:query-param("per-page", "{$per-page}", 1)
%rest:query-param("hi", "{$hi}", '')
%output:method("html5")
function PermRestItem:getItem(
$sha as xs:string*,
$id as xs:string*,
$start as xs:integer*,
$per-page as xs:integer*,
$hi as xs:string*) {
  let $item := item2:getTEIbyID($id)
  let $col := switch2:col($item/@type)
  let $log := log:add-log-message('/'||$id||'/main', sm:id()//sm:real/sm:username/string() , 'item')
  return
PermRestItem:ITEM('main', $id, $col,$start,$per-page, $hi, $sha)
};

declare
%rest:GET
%rest:path("/BetMasWeb/permanent/{$sha}/{$collection}/{$id}/main")
%rest:query-param("start", "{$start}", 1)
%rest:query-param("per-page", "{$per-page}", 1)
%rest:query-param("hi", "{$hi}", '')
%output:method("html5")
function PermRestItem:getItemC(
$sha as xs:string*,
$collection as xs:string*,
$id as xs:string*,
$start as xs:integer*,
$per-page as xs:integer*,
$hi as xs:string*) {
  let $log := log:add-log-message('/'||$collection||'/'||$id||'/main', sm:id()//sm:real/sm:username/string() , 'item')
  return
PermRestItem:ITEM('main', $id, $collection,$start,$per-page, $hi, $sha)
};


declare
%rest:GET
%rest:path("/BetMasWeb/permanent/{$sha}/{$collection}/{$id}/geoBrowser")
%rest:query-param("start", "{$start}", 1)
%rest:query-param("per-page", "{$per-page}", 1)
%rest:query-param("hi", "{$hi}", '')
%output:method("html5")
function PermRestItem:getgeoBrowser(
$sha as xs:string*,
$collection as xs:string*,
$id as xs:string*,
$start as xs:integer*,
$per-page as xs:integer*,
$hi as xs:string*) {
let $log := log:add-log-message('/'||$collection||'/'||$id||'/geoBrowser', sm:id()//sm:real/sm:username/string() , 'item')
  return
PermRestItem:ITEM('geobrowser', $id, $collection,$start,$per-page, $hi, $sha)
};

declare
%rest:GET
%rest:path("/BetMasWeb/permanent/{$sha}/{$collection}/{$id}/text")
%rest:query-param("start", "{$start}", 1)
%rest:query-param("per-page", "{$per-page}", 1)
%rest:query-param("hi", "{$hi}", '')
%output:method("html5")
function PermRestItem:gettext(
$sha as xs:string*,
$collection as xs:string*,
$id as xs:string*,
$start as xs:integer*,
$per-page as xs:integer*,
$hi as xs:string*) {
let $log := log:add-log-message('/'||$collection||'/'||$id||'/text', sm:id()//sm:real/sm:username/string() , 'item')
  return
PermRestItem:ITEM('text', $id, $collection,$start,$per-page, $hi, $sha)
};


declare
%rest:GET
%rest:path("/BetMasWeb/permanent/{$sha}/{$collection}/{$id}/analytic")
%rest:query-param("start", "{$start}", 1)
%rest:query-param("per-page", "{$per-page}", 1)
%rest:query-param("hi", "{$hi}", '')
%output:method("html5")
function PermRestItem:getanalytic(
$sha as xs:string*,
$collection as xs:string*,
$id as xs:string*,
$start as xs:integer*,
$per-page as xs:integer*,
$hi as xs:string*) {
let $log := log:add-log-message('/'||$collection||'/'||$id||'/analytic', sm:id()//sm:real/sm:username/string() , 'item')
  return
PermRestItem:ITEM('analytic', $id, $collection,$start,$per-page, $hi, $sha)
};


declare
%rest:GET
%rest:path("/BetMasWeb/permanent/{$sha}/{$collection}/{$id}/graph")
%rest:query-param("start", "{$start}", 1)
%rest:query-param("per-page", "{$per-page}", 1)
%rest:query-param("hi", "{$hi}", '')
%output:method("html5")
function PermRestItem:getgraph(
$sha as xs:string*,
$collection as xs:string*,
$id as xs:string*,
$start as xs:integer*,
$per-page as xs:integer*,
$hi as xs:string*) {
PermRestItem:ITEM('graph', $id, $collection,$start,$per-page, $hi, $sha)
};



declare
%rest:GET
%rest:path("/BetMasWeb/permanent/{$sha}/{$id}/corpus")
%rest:query-param("start", "{$start}", 1)
%rest:query-param("per-page", "{$per-page}", 1)
%rest:query-param("hi", "{$hi}", '')
%output:method("html5")
function PermRestItem:getcorpus(
$sha as xs:string*,
$id as xs:string*,
$start as xs:integer*,
$per-page as xs:integer*,
$hi as xs:string*) {
let $log := log:add-log-message('/corpus/'||$id, sm:id()//sm:real/sm:username/string() , 'item')
  return
PermRestItem:ITEM('corpus', $id, 'corpora', $start,$per-page, $hi, $sha)
};

declare function PermRestItem:ITEM($type, $id, $collection,
$start as xs:integer*,
$per-page as xs:integer*,
$hi as xs:string*,
$sha as xs:string*){
let $collect := switch2:collectionVar($collection)
let $coll := $config:data-root || '/' || $collection
let $capCol := PermRestItem:capitalize-first($collection)
let $permapath := if( $PermRestItem:deleted//t:item[. eq $id]) then (replace(string($PermRestItem:deleted//t:item[. eq $id]/@source), $collection, '') =>replace('^/', '') || '/' || $PermRestItem:deleted//t:item[. eq $id]/text() || '.xml' ) else replace(PermRestItem:capitalize-first(substring-after(base-uri(item2:getTEIbyID($id)), '/db/apps/BetMasData/')), $capCol, '')
let $docpath:= 'https://raw.githubusercontent.com/BetaMasaheft/' || $capCol || '/'||$sha||'/'|| $permapath
(:THIS WILL HAVE TO EXPAND FIRST! without storing, otherwise all functions will not work.:)

let $this:= doc($docpath)//t:TEI
let $id := $this/@xml:id
let $title := exptit:printTitle($id)
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
{($config:appUrl ||'/permanent/'|| $sha||'/' ||$id)}
</idno>

<coll>{$collection}</coll>
</bibl>
let $Cmap := map {'type': 'collection', 'name' : $collection, 'path' : $coll}
let $Imap := map {'type':  'item', 'name' :  $id, 'path' :  $collection}
return
(
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
    {scriptlinks:app-title($title)}
        <link rel="alternate" type="application/rdf+xml"
          title="RDF Representation"
          href="https://betamasaheft.eu/rdf/{$collection}/{$id}.rdf" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        {scriptlinks:app-meta($this)}
        {scriptlinks:scriptStyle()}
        {if($type='text') then () else scriptlinks:ItemScriptStyle()}
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
         {if( $PermRestItem:deleted//t:item[. eq $id]) then
<div class='w3-red w3-container'>{$PermRestItem:deleted//t:item[. eq $id]/text()} was deleted permanently on {string($PermRestItem:deleted//t:item[. eq $id]/@change)}</div>
else ()}
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
   for $document in item2:rels($id)
let $rootid := string($document/@active)
let $itemid :=substring-after($rootid, '#')
let $msid :=substring-before($rootid, '#')
return
<div class="w3-row documentcorpus w3-panel w3-leftbar">
{
let $doc := doc(base-uri($document))//id($itemid)
return
(
<div class="w3-col" style="width:15%">
<a href="{$msid}" >{exptit:printTitle($msid)}</a><br/>
     <a href="/{$rootid}">{if($doc/t:title) then string:additionstitles($doc/t:title/node()) else if($doc/t:desc/@type) then string($doc/t:desc/@type) else $itemid}</a>
    ({string:additionstitles($doc/t:locus)})
     
     </div>,
<div class="w3-rest">{viewItem:documents($doc)}</div>
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
                  {item2:EntityRelsTable($this, $collection)}
            </div>
            </div>
            <div class="w3-container">
            <div class="w3-half w3-padding">
            <div id="timeLine" class="w3-container"/>
                <script type="text/javascript">
            {item2:timeline($this, $collection)}
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
   then dtsc:text($id, $this//t:div[@type eq 'edition'], '', '', '', $collection) else <p>No text available here.</p>}</div>
   <!--<div class="w3-third w3-gray w3-padding">{item2:textBibl($this, $id)}</div>-->
   </div>
    ,
   for $contains in $this//t:relation[@name eq "saws:contains"]/@passive 
     let $ids:=  if(contains($contains, ' ')) then for $x in tokenize($contains, ' ') return $x else string($contains)
     for $contained in $ids
    let $cfile := item2:getTEIbyID($contained)
   return 
   
   <div class="w3-container">
   {<div class="w3-twothird" id="dtstext">Contains  {item2:title($contained)}
   {if ($cfile//t:div[@type eq 'edition']) 
   then dtsc:text($contained, '', '', '', '', 'works') else ()}</div>,
   <!--<div class="w3-third w3-gray w3-padding">{item2:textBibl($this, $id)}</div>-->
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
let $Subjects := doc(concat($config:data-rootA, '/taxonomy.xml'))//t:category[t:desc eq 'Subjects']//t:category/t:catDesc/text()
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
   
        
(:   item2:namedentitiescorresps($this, $collection),:)
(:   the form with a list of potental relation keywords to find related items. value is used by Jquery to query rest again on api:SharedKeyword($keyword) :)
   switch($collection)
   case 'works' return  (
   item2:RestMiniatures($id))
  case 'persons' return (item2:RestTabot($id), item2:RestAdditions($id), item2:RestMiniatures($id))
    case 'authority-files' return
    <div class="w3-container"><h4>Art Objects associated with this Art Theme in miniatures and other manuscript decorations</h4>

<div  class="w3-panel w3-red">
{item2:RestMiniaturesKeys($id)}
</div>

<div  class="w3-panel w3-red">
{item2:RestMiniatures($id)}</div>
</div>
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
   <div class="w3-container w3-padding w3-card-4 " id="permanentIDs" style="max-heigh:400px;overflow:auto"
   data-path="{$permapath}" 
   data-id="{$id}" data-type="{PermRestItem:capitalize-first($collection)}">YOU ARE LOOKING AT VERSION
   {$sha}. <a class="w3-btn w3-gray" id="LoadPermanentIDs">See all permalinks.</a></div>
   <script  type="text/javascript" src="resources/js/permanentID.js"></script>
   
   </div>
  { item2:authorsSHA($id, $this, $collection, $sha)}
   </div>


</div>

        {nav:footerNew()}

       {scriptlinks:ItemFooterScript()}

    </body>
</html>
        )
};

