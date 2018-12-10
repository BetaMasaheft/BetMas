xquery version "3.1" encoding "UTF-8";
(:~
 : module for the different list views, decides what kind of list it is, in which way to display it and calls the correct functions
 :
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)
module namespace list = "https://www.betamasaheft.uni-hamburg.de/BetMas/list";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMas/modules/log.xqm";
import module namespace app = "https://www.betamasaheft.uni-hamburg.de/BetMas/app" at "xmldb:exist:///db/apps/BetMas/modules/app.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMas/string" at "xmldb:exist:///db/apps/BetMas/modules/tei2string.xqm";
import module namespace item = "https://www.betamasaheft.uni-hamburg.de/BetMas/item" at "xmldb:exist:///db/apps/BetMas/modules/item.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMas/nav" at "xmldb:exist:///db/apps/BetMas/modules/nav.xqm";
import module namespace error = "https://www.betamasaheft.uni-hamburg.de/BetMas/error" at "xmldb:exist:///db/apps/BetMas/modules/error.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMas/apprest" at "xmldb:exist:///db/apps/BetMas/modules/apprest.xqm";
import module namespace charts = "https://www.betamasaheft.uni-hamburg.de/BetMas/charts" at "xmldb:exist:///db/apps/BetMas/modules/charts.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace kwic = "http://exist-db.org/xquery/kwic"
    at "resource:org/exist/xquery/lib/kwic.xql";

(: For interacting with the TEI document :)
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace dcterms = "http://purl.org/dc/terms";
declare namespace saws = "http://purl.org/saws/ontology";
declare namespace cmd = "http://www.clarin.eu/cmd/";


(:~ For REST annotations :)
declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";

declare variable $list:app-meta := <meta  xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $genauthor in $config:repo-descriptor/repo:author
    return
        <meta xmlns="http://www.w3.org/1999/xhtml" name="creator" content="{$genauthor/text()}"></meta>;


declare
%rest:GET
%rest:path("/BetMas/manuscripts/browse")
%output:method("html5")
function list:browseMS(){
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
        <link rel="shortcut icon" href="resources/images/minilogo.ico"></link>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"></meta>
       
    {apprest:scriptStyle()}
    </head>
    <body id="body">
        {nav:bar()}
        {nav:modals()}
        {nav:searchhelp()}
<div class="container">
<div class="alert alert-info">Here you can browse all shelfmarks available institution by institution and collection by collection.</div>
{
let $mss := collection($config:data-rootMS)[descendant::t:repository[@ref]]
return
    for $repoi in doc('/db/apps/BetMas/institutions.xml')//t:item
    let $i := string($repoi/@xml:id)
    
     let $inthisrepo := $mss//t:repository[@ref = $i]
     let $count := count($inthisrepo)
    order by $repoi
    return
        <div class="row">
        <div class="col-md-4"><h2><a href="/manuscripts/{$i}/list">{$repoi}</a></h2></div>
        <div class="col-md-2"><span class="badge">{$count}</span></div>
          <div class="col-md-6">   <a class="btn btn-info" data-toggle="collapse" href="#list{$i}" role="button" aria-expanded="false" aria-controls="list{$i}">show list</a>
            <ul id="list{$i}" class="collapse">{
                    for $m in $inthisrepo
                    
                    let $collection := root($m)//t:collection
                        group by $C := $collection[1]
                        order by $C
                    return
                        <li>
                            <p
                                class="lead">{$C} <span class="badge">{string(count($m))}</span></p>
                            <ul>{
                                    for $mcol in $m
                                    let $r := root($mcol)
                                    let $mainID := ($r//t:idno)[1]/text()
                                    order by $mainID
                                    return
                                        <li><a
                                                href="/{string($r/t:TEI/@xml:id)}">{string-join($r//t:idno/text(), ', ')}</a></li>
                                }
                            </ul>
                        </li>
                        
                }
            </ul>
            </div>
        </div>
        }
</div>
        {nav:footer()}

       <script type="text/javascript" src="resources/js/printgroupbutton.js"/>
       <script type="text/javascript" src="resources/js/printgroup.js"/>
        <script type="text/javascript" src="resources/js/toogle.js"/>
        <script type="text/javascript" src="resources/js/titles.js"/>
        <script type="text/javascript" src="resources/js/clavisid.js"/>
        <script type="text/javascript" src="resources/js/datatable.js"/>
        <script type="text/javascript" src="resources/js/lookup.js"/>
        <script type="text/javascript" src="resources/js/NewBiblio.js"/>
        </body>
        </html>
       )
        
        };
        
        
        
declare
%rest:GET
%rest:path("/BetMas/Uni{$unitType}/browse")
%output:method("html5")
function list:browseUnits($unitType){
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

        <meta property="og:site_name" content="Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea"/>
        <meta property="dcterms:language schema:inLanguage" content="en"/>
        <meta property="dcterms:rights" content="Copyright © Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik.  Sharing and remixing permitted under terms of the Creative Commons Attribution Share alike Non Commercial 4.0 License (cc-by-nc-sa)."/>
        <meta property="dcterms:publisher schema:publisher" content="Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik"/>
        
        
{apprest:scriptStyle()}
    </head>
    <body id="body">
        {nav:bar()}
        {nav:modals()}
        {nav:searchhelp()}
<div class="container">
<div class="col-md-12" id="result" data-value="{$unitType}"/>
<script type="application/javascript" src="resources/js/UnitList.js"/>
</div>
        {nav:footer()}

        <script type="text/javascript" src="resources/js/titles.js"/>
        </body>
        </html>
       )
        
        };
        
        
declare
%rest:GET
%rest:path("/BetMas/{$collection}/list")
%rest:query-param("start", "{$start}", 1)
%rest:query-param("keyword", "{$keyword}", "")
%rest:query-param("mainname", "{$mainname}", "")
%rest:query-param("language", "{$language}", "")
%rest:query-param("prms", "{$prms}", "")
%rest:query-param("per-page", "{$per-page}", 20)
%rest:query-param("date-range", "{$date-range}", "")
%rest:query-param("clavisID", "{$clavisID}", "")
%rest:query-param("clavistype", "{$clavistype}", "")
%rest:query-param("cp", "{$cp}", "")
%rest:query-param("numberOfParts", "{$numberOfParts}", "")
%rest:query-param("min-hits", "{$min-hits}", 0)
%rest:query-param("max-pages", "{$max-pages}", 20)
 %rest:query-param("height","{$height}", "")
%rest:query-param("width","{$width}", "")
%rest:query-param("depth","{$depth}", "")
%rest:query-param("columnsNum","{$columnsNum}", "")
%rest:query-param("tmargin","{$tmargin}", "")
%rest:query-param("bmargin","{$bmargin}", "")
%rest:query-param("rmargin","{$rmargin}", "")
%rest:query-param("lmargin","{$lmargin}", "")
%rest:query-param("intercolumn","{$intercolumn}", "")
%rest:query-param("folia","{$folia}", "")
%rest:query-param("qn","{$qn}", "")
%rest:query-param("qcn","{$qcn}", "")
%rest:query-param("wL","{$wL}", "")
%rest:query-param("script","{$script}", "")
%rest:query-param("scribe","{$scribe}", "")
%rest:query-param("donor","{$donor}", "")
%rest:query-param("patron","{$patron}", "")
%rest:query-param("owner","{$owner}", "")
%rest:query-param("binder","{$binder}", "")
%rest:query-param("parchmentMaker","{$parchmentMaker}", "")
%rest:query-param("objectType","{$objectType}", "")
%rest:query-param("material","{$material}", "")
%rest:query-param("bmaterial","{$bmaterial}", "")
%rest:query-param("contents","{$contents}", "")
%rest:query-param("origPlace","{$origPlace}", "")
%rest:query-param("tabot","{$tabot}", "")
%rest:query-param("placetype","{$placetype}", "")
%rest:query-param("authors","{$authors}", "")
%rest:query-param("occupation","{$occupation}", "")
%rest:query-param("faith","{$faith}", "")
%rest:query-param("gender","{$gender}", "")
%rest:query-param("period","{$period}", "")
%rest:query-param("restorations","{$restorations}", "")
%rest:query-param("country","{$country}", "")
%rest:query-param("settlement","{$settlement}", "")
%output:method("html5")
function list:getlist(
$collection as xs:string*,
$start as xs:integer*,
$per-page as xs:integer*,
$min-hits as xs:integer*,
$max-pages as xs:integer*,
$date-range as xs:string*,
$keyword as xs:string*,
$mainname as xs:string*,
$clavisID as xs:string*,
$clavistype as xs:string*,
$cp as xs:string*,
$language as xs:string*,
$numberOfParts as xs:string*,
 $height as xs:string* ,
$width as xs:string* ,
$depth as xs:string* ,
$columnsNum as xs:string* ,
$tmargin as xs:string* ,
$bmargin as xs:string* ,
$rmargin as xs:string* ,
$lmargin as xs:string* ,
$intercolumn as xs:string* ,
$folia as xs:string* ,
$qn as xs:string* ,
$qcn as xs:string* ,
$wL as xs:string* ,
$script as xs:string* ,
$scribe as xs:string* ,
$donor as xs:string* ,
$patron as xs:string* ,
$owner as xs:string* ,
$binder as xs:string* ,
$parchmentMaker as xs:string* ,
$objectType as xs:string* ,
$material as xs:string* ,
$bmaterial as xs:string* ,
$contents as xs:string* ,
$origPlace as xs:string* ,
$tabot as xs:string* ,
$placetype as xs:string* ,
$authors as xs:string* ,
$occupation as xs:string* ,
$faith as xs:string* ,
$gender as xs:string* ,
$period as xs:string* ,
$restorations as xs:string* ,
$country as xs:string* ,
$settlement as xs:string* ,
$prms as xs:string*) {
let $c := '/db/apps/BetMas/data/' || $collection
let $log := log:add-log-message('/'||$collection||'/list', xmldb:get-current-user(), 'list')
let $Cmap := map {'type':= 'collection', 'name' := $collection, 'path' := $c}
let $parameters :=
map{'key':=$keyword,
'mainname':=$mainname,
                           'lang':=$language,
                           'date':=$date-range,
                           'clavisID':=$clavisID,
                           'clavistype':=$clavistype,
                           'cp':=$cp,
                           'numberOfParts':=$numberOfParts,
                           'height':=$height,
'width':=$width,
'depth':=$depth,
'columnsNum':=$columnsNum,
'tmargin':=$tmargin,
'bmargin':=$bmargin,
'rmargin':=$rmargin,
'lmargin':=$lmargin,
'intercolumn':=$intercolumn,
'folia':=$folia,
'qn':=$qn,
'qcn':=$qcn,
'wL':=$wL,
'script':=$script,
'scribe':=$scribe,
'donor':=$donor,
'patron':=$patron,
'owner':=$owner,
'binder':=$binder,
'parchmentMaker':=$parchmentMaker,
'objectType':=$objectType,
'material':=$material,
'bmaterial':=$bmaterial,
'contents':=$contents,
'origPlace':=$origPlace,
'tabot':=$tabot,
'placetype':=$placetype,
'authors':=$authors,
'occupation':=$occupation,
'faith':=$faith,
'gender':=$gender,
'period':=$period,
'restorations':=$restorations,
'country':=$country,
'settlement':=$settlement
}

return
(:
needs to add all the parameters added to the mss query to the parameters variable, and thus also to the list of parameters for the function
then in apprest:listrest() all these need to be taken into account for the query:)

if(xdb:collection-available($c)) then (
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
        <link rel="shortcut icon" href="resources/images/minilogo.ico"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        {$list:app-meta}
{apprest:scriptStyle()}
    </head>
    <body id="body">
        {nav:bar()}
        {nav:modals()}
        {nav:searchhelp()}

 <div id="content" class="container-fluid col-md-12">
 {if($collection = 'authority-files') then (
 <div class="col-md-12">
 <div class="col-md-2" data-hint="The values listed here all come from the taxonomy. Click on one of them to see which entities point to it.">
 {for $cat in doc($c||'/taxonomy.xml')//t:category[not(parent::t:category)]
 let $val := $cat/t:desc/text()
 return
 <div class="row">
 <p class="lead" href="/{$collection}/{$val}">{$val}<span class="badge">{count($cat/t:category)}</span></p>
 <ul>{for $subcat in $cat/t:category
 return
 if($subcat/t:desc) then (
 let $subval := $subcat/t:desc
 return
 <li><p class="lead" href="/{$collection}/{$subval}">{$subval}<span class="badge">{count($subcat/t:category)}</span></p>
 <ul>
 {for $c in  $subcat/t:category
 let $subsubval := $c/t:catDesc/text()
 return
 <li><a href="/{$collection}/list?keyword={$subsubval}">{collection($config:data-rootA)//id($subsubval)//t:titleStmt/t:title/text()}</a></li>

 }
 </ul></li>
 ) else
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
 {if($keyword = '')
 then (<p class="lead">Select an entry on the left to see all records where this occurs.</p>, <span class="pull-right">{app:nextID($collection)}</span>)
 else (
 let $res :=
 let $c := collection($config:data-root)
 let $terms := $c/t:TEI[descendant::t:term[@key = $keyword]]
 let $title := $c/t:TEI[descendant::t:title[@type = $keyword]]
 let $person := $c/t:TEI[descendant::t:person[@type = $keyword]]
 let $desc := $c/t:TEI[descendant::t:desc[@type = $keyword] ]
 let $place := $c/t:TEI[descendant::t:place[@type = $keyword] ]
 let $ab := $c/t:TEI[descendant::t:ab[@type = $keyword] ]
 let $faith := $c/t:TEI[descendant::t:faith[@type = $keyword] ]
 let $occupation := $c/t:TEI[descendant::t:occupation[@type = $keyword]]
 let $ref := $c/t:TEI[descendant::t:ref[@type = 'authFile'][@corresp=$keyword]]
 let $all := ($terms,$title,$person,$desc,$place,$ab,$faith,$occupation,$ref)
 let $hits :=  for $resource in $all
                         return $resource
   return
                      map {
                      'hits' := $hits,
                      'collection' := $collection
                      }

   return
 <div class="col-md-12">
 <div><h1><a href="/authority-files/{$keyword}/main">{titles:printTitleMainID($keyword)}</a></h1>
 {let $file := collection($config:data-rootA)//id($keyword)
 for $element in ($file//t:abstract, $file//t:listBibl)
 return <p>{string:tei2string($element)}</p>}
 </div>
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
 let $parametersLenght := map:for-each($parameters, function($key, $value){if($value = '') then 0 else 1})
 return
if(sum($parametersLenght) ge 1 ) then 
 
        let $hits := apprest:listrest('collection', $collection, $parameters, $prms)
    return
    (
   <div class="col-md-12">
   <span id="hit-count" class="lead">
   {'There are ' || count($hits("hits")) || ' records in this selection of ' || $collection }
   </span>
   {if ($collection = 'works') 
   then
   let $texts :=  $hits('hits')[descendant::t:div[@type='edition']//t:ab//text()] 
   return
   if(count($texts) lt 100) then 
  let $ids := for $hit in $texts return 'input=http://betamasaheft.eu/works/'||string($hit/@xml:id)||'.xml'
  let $urls := string-join($ids,'&amp;')
   return
   <a style="margin-left:30px;" role="button" target="_blank" class="btn btn-primary" href="{concat('http://voyant-tools.org/?', $urls)}">Voyant (v.2) Analysis Tools</a>
  else if (count($texts) eq 0) then 
  (<span class="alert alert-warning">No text available for analysis with Voyant Tools for this selection.</span>)
  else (<span class="alert alert-info">With less than 100 hits, you will find here a button to analyse the available texts in your selection with Voyant Tools.</span>)
        else ()   }
{list:paramsList($parameters)}
                   </div>
                   ,
    <div class="col-md-2">
    {apprest:searchFilter-rest($collection, $hits)}
    {switch($collection)
    case 'manuscripts' return (apprest:institutions(),apprest:catalogues())
    default return ()}
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
                {if($collection = 'manuscripts') then ( if(count($hits("hits")) lt 1050) then charts:chart($hits("hits")) 
                else (<div  class="col-md-6 alert alert-danger"><p>
    We think that charts with data from {count($hits("hits"))} items would be impossible to read and not very useful. 
    Filter your search to limit the number of items, with less then 1000 items we will also dinamically produce the charts.
  </p></div>)) else ()}
        <div></div>
        </div>)
        
        else  (<div class="col-md-2" data-hint="The following filters can be applied by clicking on the filter icon below, to return to the full list, click the list, to go to advanced search the cog">
    {
    apprest:searchFilter-rest($collection, map{'hits' := <start/>, 'query' := ("collection('/db/apps/BetMas/data/"|| $collection || "')")})}
    {switch($collection)
    case 'manuscripts' return (apprest:institutions(),apprest:catalogues())
    default return ()}
    </div>,<div class="col-md-10 alert alert-info">Please, select a filter.</div>
        )
        }
        <a class="btn btn-large btn-success" href="javascript:void(0);" onclick="javascript:introJs().addHints();">show hints</a>
</div>

        {nav:footer()}

       <script type="text/javascript" src="resources/js/printgroupbutton.js"/>
       <script type="text/javascript" src="resources/js/printgroup.js"/>
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
%rest:query-param("mainname", "{$mainname}", "")
%rest:query-param("language", "{$language}", "")
%rest:query-param("prms", "{$prms}", "")
%rest:query-param("per-page", "{$per-page}", 20)
%rest:query-param("date-range", "{$date-range}", "")
%rest:query-param("numberOfParts", "{$numberOfParts}", "")
%rest:query-param("min-hits", "{$min-hits}", 0)
%rest:query-param("max-pages", "{$max-pages}", 20)
 %rest:query-param("height","{$height}", "")
%rest:query-param("width","{$width}", "")
%rest:query-param("depth","{$depth}", "")
%rest:query-param("columnsNum","{$columnsNum}", "")
%rest:query-param("tmargin","{$tmargin}", "")
%rest:query-param("bmargin","{$bmargin}", "")
%rest:query-param("rmargin","{$rmargin}", "")
%rest:query-param("lmargin","{$lmargin}", "")
%rest:query-param("intercolumn","{$intercolumn}", "")
%rest:query-param("folia","{$folia}", "")
%rest:query-param("qn","{$qn}", "")
%rest:query-param("qcn","{$qcn}", "")
%rest:query-param("wL","{$wL}", "")
%rest:query-param("script","{$script}", "")
%rest:query-param("scribe","{$scribe}", "")
%rest:query-param("donor","{$donor}", "")
%rest:query-param("patron","{$patron}", "")
%rest:query-param("owner","{$owner}", "")
%rest:query-param("binder","{$binder}", "")
%rest:query-param("parchmentMaker","{$parchmentMaker}", "")
%rest:query-param("objectType","{$objectType}", "")
%rest:query-param("material","{$material}", "")
%rest:query-param("bmaterial","{$bmaterial}", "")
%rest:query-param("contents","{$contents}", "")
%rest:query-param("origPlace","{$origPlace}", "")
%output:method("html5")
function list:getrepolist(
$repoID as xs:string*,
$start as xs:integer*,
$per-page as xs:integer*,
$min-hits as xs:integer*,
$max-pages as xs:integer*,
$date-range as xs:string*,
$numberOfParts as xs:string*,
$keyword as xs:string*,
$language as xs:string*,
 $height as xs:string* ,
$width as xs:string* ,
$depth as xs:string* ,
$columnsNum as xs:string* ,
$tmargin as xs:string* ,
$bmargin as xs:string* ,
$rmargin as xs:string* ,
$lmargin as xs:string* ,
$intercolumn as xs:string* ,
$folia as xs:string* ,
$qn as xs:string* ,
$qcn as xs:string* ,
$wL as xs:string* ,
$script as xs:string* ,
$scribe as xs:string* ,
$donor as xs:string* ,
$patron as xs:string* ,
$owner as xs:string* ,
$binder as xs:string* ,
$parchmentMaker as xs:string* ,
$objectType as xs:string* ,
$material as xs:string* ,
$bmaterial as xs:string* ,
$contents as xs:string* ,
$origPlace as xs:string* ,
$prms as xs:string*,
$mainname as xs:string*) {

(:the file for that institution:)
let $repos := '/db/apps/BetMas/data/institutions/'
let $log := log:add-log-message('/manuscripts/'||$repoID||'/list', xmldb:get-current-user(), 'list')
let $Cmap := map {'type':= 'repo', 'name' := $repoID, 'path' := $repos}
let $parameters := map{'key':=$keyword,
'lang':=$language,'date':=$date-range,'numberOfParts':=$numberOfParts,  'height':=$height,

'mainname':=$mainname,
'width':=$width,
'depth':=$depth,
'columnsNum':=$columnsNum,
'tmargin':=$tmargin,
'bmargin':=$bmargin,
'rmargin':=$rmargin,
'lmargin':=$lmargin,
'intercolumn':=$intercolumn,
'folia':=$folia,
'qn':=$qn,
'qcn':=$qcn,
'wL':=$wL,
'script':=$script,
'scribe':=$scribe,
'donor':=$donor,
'patron':=$patron,
'owner':=$owner,
'binder':=$binder,
'parchmentMaker':=$parchmentMaker,
'objectType':=$objectType,
'material':=$material,
'bmaterial':=$bmaterial,
'contents':=$contents,
'origPlace':=$origPlace}
let $file := collection($config:data-rootIn)//id($repoID)[name()='TEI']
return


if($file) then (
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
        <link rel="shortcut icon" href="resources/images/minilogo.ico"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        {$list:app-meta}
{apprest:scriptStyle()}
<link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/mapbox.css"/>
        <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/leaflet.css"/>
        <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/leaflet.fullscreen.css"/>
        <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/leaflet-search.css"/>
       <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="http://cdn.leafletjs.com/leaflet/v0.7.7/leaflet.js"/>
        <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="resources/js/mapbox.js"/>
        <script  xmlns="http://www.w3.org/1999/xhtml"type="text/javascript" src="resources/js/Leaflet.fullscreen.min.js"/>
        <script  xmlns="http://www.w3.org/1999/xhtml"type="text/javascript" src="resources/js/leaflet-search.js"/>
         <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="resources/js/leaflet-ajax-gh-pages/dist/leaflet.ajax.min.js"></script>

    </head>
    <body id="body">
        {nav:bar()}
        {nav:modals()}
        {nav:searchhelp()}
       <div class="col-md-3">
       {item:RestItem($file, 'institutions')}
       {item:mainRels($file, 'institutions')}
       <div class="col-md-12">
       <iframe
   style="border:none;"
                allowfullscreen="true"
                width="100%" 
                height="400" 
                src="https://peripleo.pelagios.org/embed/{encode-for-uri(concat('http://betamasaheft.eu/places/',$repoID))}">
            </iframe>
       <div id="entitymap" style="width: 100%; height: 400px; margin-top:100px" />
   <script>{'var placeid = "'||$repoID||'"'}</script>
   <script  type="text/javascript" src="resources/geo/geojsonentitymap.js"></script></div>

        {apprest:EntityRelsTable($file, 'institutions')}
       </div>
 <div id="content" class="container-fluid col-md-9">
 {let $hits := apprest:listrest('repo', $repoID, $parameters, $prms)
    return
    (
   <div class="col-md-12">
   <span id="hit-count" class="lead">
   {'There are ' || count($hits("hits")) || ' manuscripts at ' || titles:printTitleID($repoID) }
   </span>
{list:paramsList($parameters)}
{<a target="_blank" class="btn btn-warning" href="/manuscripts/{$repoID}/list/viewer">Images available for this repository</a>}

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
                {charts:chart($hits("hits"))}

        </div>)
        }
</div>

        {nav:footer()}

       <script type="text/javascript" src="resources/js/printgroupbutton.js"/>
       <script type="text/javascript" src="resources/js/printgroup.js"/>
        <script type="text/javascript" src="resources/js/toogle.js"/>
        <script type="text/javascript" src="resources/js/titles.js"/>
        <script type="text/javascript" src="resources/js/clavisid.js"/>
        <script type="text/javascript" src="resources/js/datatable.js"/>
        <script type="text/javascript" src="resources/js/lookup.js"/>
        <script type="text/javascript" src="resources/js/NewBiblio.js"/>
<script type="text/javascript" src="resources/js/allattestations.js"/>
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
(log:add-log-message('/catalogues/list', xmldb:get-current-user(), 'list'),
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
        <link rel="shortcut icon" href="resources/images/minilogo.ico"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        {$list:app-meta}
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
    <table class="table table-striped">
    <tbody>
    {
    let $cats := collection($config:data-rootMS)//t:listBibl[@type='catalogue']
   for $catalogue in distinct-values($cats//t:ptr/@target)
   let $zoTag := substring-after($catalogue, 'bm:')
   let $count := count($cats//t:ptr[@target=$catalogue])
	let $xml-url := concat('https://api.zotero.org/groups/358366/items?&amp;tag=', $catalogue, '&amp;format=bib&amp;style=hiob-ludolf-centre-for-ethiopian-studies')
let $data := httpclient:get(xs:anyURI($xml-url), true(), <Headers/>)
order by $data
return
    <tr>
    <td><a href="/catalogues/{$zoTag}/list" class="lead">{$data}</a></td>
    <td><span class="badge">{$count}</span></td>
    </tr>
    }</tbody></table>
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
%rest:query-param("date-range", "{$date-range}", "")
%rest:query-param("numberOfParts", "{$numberOfParts}", "")
%rest:query-param("min-hits", "{$min-hits}", 0)
%rest:query-param("max-pages", "{$max-pages}", 20)
 %rest:query-param("height","{$height}", "")
%rest:query-param("width","{$width}", "")
%rest:query-param("depth","{$depth}", "")
%rest:query-param("columnsNum","{$columnsNum}", "")
%rest:query-param("tmargin","{$tmargin}", "")
%rest:query-param("bmargin","{$bmargin}", "")
%rest:query-param("rmargin","{$rmargin}", "")
%rest:query-param("lmargin","{$lmargin}", "")
%rest:query-param("intercolumn","{$intercolumn}", "")
%rest:query-param("folia","{$folia}", "")
%rest:query-param("qn","{$qn}", "")
%rest:query-param("qcn","{$qcn}", "")
%rest:query-param("wL","{$wL}", "")
%rest:query-param("script","{$script}", "")
%rest:query-param("scribe","{$scribe}", "")
%rest:query-param("donor","{$donor}", "")
%rest:query-param("patron","{$patron}", "")
%rest:query-param("owner","{$owner}", "")
%rest:query-param("binder","{$binder}", "")
%rest:query-param("parchmentMaker","{$parchmentMaker}", "")
%rest:query-param("objectType","{$objectType}", "")
%rest:query-param("material","{$material}", "")
%rest:query-param("bmaterial","{$bmaterial}", "")
%rest:query-param("contents","{$contents}", "")
%rest:query-param("origPlace","{$origPlace}", "")
%output:method("html5")
function list:getcataloguelist(
$catalogueID as xs:string*,
$start as xs:integer*,
$per-page as xs:integer*,
$min-hits as xs:integer*,
$max-pages as xs:integer*,
$date-range as xs:string*,
$numberOfParts as xs:string*,
$keyword as xs:string*,
$language as xs:string*,
 $height as xs:string* ,
$width as xs:string* ,
$depth as xs:string* ,
$columnsNum as xs:string* ,
$tmargin as xs:string* ,
$bmargin as xs:string* ,
$rmargin as xs:string* ,
$lmargin as xs:string* ,
$intercolumn as xs:string* ,
$folia as xs:string* ,
$qn as xs:string* ,
$qcn as xs:string* ,
$wL as xs:string* ,
$script as xs:string* ,
$scribe as xs:string* ,
$donor as xs:string* ,
$patron as xs:string* ,
$owner as xs:string* ,
$binder as xs:string* ,
$parchmentMaker as xs:string* ,
$objectType as xs:string* ,
$material as xs:string* ,
$bmaterial as xs:string* ,
$contents as xs:string* ,
$origPlace as xs:string* ,
$prms as xs:string*) {

(:the file for that institution:)

let $log := log:add-log-message('/catalogues/'||$catalogueID||'/list', xmldb:get-current-user(), 'list')
let $catalogues := for $catalogue in distinct-values(collection($config:data-rootMS)//t:listBibl[@type='catalogue']//t:ptr/@target)
	return $catalogue
	let $prefixedcatID := 'bm:' ||$catalogueID
let $Cmap := map {'type':= 'catalogue', 'name' := $catalogueID, 'path' := $catalogues}
let $parameters := map{'key':=$keyword,'lang':=$language,'date':=$date-range,'numberOfParts':=$numberOfParts,  'height':=$height,
'width':=$width,
'depth':=$depth,
'columnsNum':=$columnsNum,
'tmargin':=$tmargin,
'bmargin':=$bmargin,
'rmargin':=$rmargin,
'lmargin':=$lmargin,
'intercolumn':=$intercolumn,
'folia':=$folia,
'qn':=$qn,
'qcn':=$qcn,
'wL':=$wL,
'script':=$script,
'scribe':=$scribe,
'donor':=$donor,
'patron':=$patron,
'owner':=$owner,
'binder':=$binder,
'parchmentMaker':=$parchmentMaker,
'objectType':=$objectType,
'material':=$material,
'bmaterial':=$bmaterial,
'contents':=$contents,
'origPlace':=$origPlace}
return


if($prefixedcatID = $catalogues) then (
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
        <link rel="shortcut icon" href="resources/images/minilogo.ico"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        {$list:app-meta}
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

      <h1>{let $xml-url := concat('https://api.zotero.org/groups/358366/items?&amp;tag=', $prefixedcatID, '&amp;format=bib&amp;style=hiob-ludolf-centre-for-ethiopian-studies')
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
   {list:paramsList($parameters)}
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

                {charts:chart($hits('hits'))}
        </div>)
        }
</div>

        </div>
        {nav:footer()}

       <script type="text/javascript" src="resources/js/printgroupbutton.js"/>
       <script type="text/javascript" src="resources/js/printgroup.js"/>
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

declare function list:paramsList($parameters as map(*)){
   <div class="container well">
   {map:for-each($parameters,
   function($key, $value) {
   if($value = '') then ()
   else  if ($key = 'date')
                     then (
                     if($value = '0,2000') then ()
   else<button type="button" class="btn btn-sm btn-info">{'with a date (anywhere in the description) between ' || substring-before($value, ',') || ' and ' || substring-after($value, ',')}</button>)
   else  if ($key = 'wL')
                     then (if($value = '1,100') then ()
   else <button type="button" class="btn btn-sm btn-info">{'between ' || substring-before($value, ',') || ' and ' || substring-after($value, ',')}</button>)
   else  if ($key = 'folia')
                     then (if($value = '1,1000') then ()
   else <button type="button" class="btn btn-sm btn-info">{'between ' || substring-before($value, ',') || ' and ' || substring-after($value, ',') ||' leaves' }</button>)
   else  if ($key = 'qn')
                     then (if($value = '1,100') then ()
   else <button type="button" class="btn btn-sm btn-info">{'between ' || substring-before($value, ',') || ' and ' || substring-after($value, ',') || ' quires in the manuscript'}</button>)
   else  if ($key = 'qcn')
                     then (if($value = '1,40') then ()
   else <button type="button" class="btn btn-sm btn-info">{'between ' || substring-before($value, ',') || ' and ' || substring-after($value, ',') ||' leaves in at least one quire in the manuscript' }</button>)

   else
   <button type="button" class="btn btn-sm btn-info">{$key|| ": ", <span class="badge">{ $value }</span>}</button>})}
   </div>

};
