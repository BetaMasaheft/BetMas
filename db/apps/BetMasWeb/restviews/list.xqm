xquery version "3.1" encoding "UTF-8";
(:~
 : module for the different list views, decides what kind of list it is, in which way to display it and calls the correct functions
 :
 : @author Pietro Liuzzo
 :)
module namespace list = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/list";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace apptable = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/apptable" at "xmldb:exist:///db/apps/BetMasWeb/modules/apptable.xqm";
import module namespace exptit="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/string" at "xmldb:exist:///db/apps/BetMasWeb/modules/tei2string.xqm";
import module namespace item2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/item2" at "xmldb:exist:///db/apps/BetMasWeb/modules/item.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/nav" at "xmldb:exist:///db/apps/BetMasWeb/modules/nav.xqm";
import module namespace error = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/error" at "xmldb:exist:///db/apps/BetMasWeb/modules/error.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/apprest" at "xmldb:exist:///db/apps/BetMasWeb/modules/apprest.xqm";
import module namespace scriptlinks = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/scriptlinks" at "xmldb:exist:///db/apps/BetMasWeb/modules/scriptlinks.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace charts = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/charts" at "xmldb:exist:///db/apps/BetMasWeb/modules/charts.xqm";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/switch2"  at "xmldb:exist:///db/apps/BetMasWeb/modules/switch2.xqm";
import module namespace exreq = "http://exquery.org/ns/request";
import module namespace xdb="http://exist-db.org/xquery/xmldb";
(: For interacting with the TEI document :)
declare namespace b = "betmas.biblio";
declare namespace http = "http://expath.org/ns/http-client";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace dcterms = "http://purl.org/dc/terms";
declare namespace saws = "http://purl.org/saws/ontology";
declare namespace cmd = "http://www.clarin.eu/cmd/";


(:~ For REST annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";
declare variable $list:instit := doc('/db/apps/lists/institutions.xml') ;
declare variable $list:taxonomy := doc('/db/apps/lists/canonicaltaxonomy.xml') ;
declare variable $list:catalogues := doc('/db/apps/lists/catalogues.xml')//t:list;
declare variable $list:bibliography := doc('/db/apps/lists/bibliography.xml');
declare variable $list:app-meta := (<meta  xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $genauthor in $config:repo-descriptor/repo:author
    return
        <meta xmlns="http://www.w3.org/1999/xhtml" name="creator" content="{$genauthor/text()}"></meta>);


declare
%rest:GET
%rest:path("/BetMasWeb/manuscripts/browse")
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
        <link rel="shortcut icon" href="{$config:appUrl}/resources/images/minilogo.ico"></link>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"></meta>

    {scriptlinks:scriptStyle()}
    </head>
    <body id="body">
        {nav:barNew()}
        {nav:modalsNew()}
<div class="w3-main w3-margin w3-padding-64">
<div class="w3-panel w3-card-4 w3-padding w3-margin">Here you can browse all shelfmarks available institution by institution and collection by collection. <span class="w3-hide-small">The letters on the right may speed up scrolling down the list.</span></div>
<div class="w3-container">
{
let $mss := $apprest:collection-rootMS[descendant::t:repository[@ref]]
return
(
 <div class="w3-row w3-hide-small" style="right: 0px;width: 300px;width:30%;position: fixed;">
 <div class="w3-bar">
 <a class="w3-bar-item page-scroll" href="#group-A">top</a>{
 let $letter := for $repoi at $p in $list:instit//t:item return upper-case(substring(replace($repoi/string(), '\s', ''), 1, 1))
   for $l in distinct-values($letter)
   order by $l
   return
   <a class="w3-bar-item page-scroll" href="#group-{$l}">{$l}</a>
   }</div></div>
,
<div style="left:300px">{
	let $reposByRepoId := map:merge(
		for $ref in $mss//t:repository[@ref]
			group by $r := $ref/@ref
			return map:entry($r, $ref)
		)
	return

    for $repoi at $p in $list:instit//t:item
    let $firstletter := upper-case(substring($repoi/string(), 1, 1))
    group by $First := $firstletter
    order by $First
    return
    if($First='') then () else
    <div id="group-{$First}">
    <h3>{$First}</h3>
    {
    for $rep in $repoi
    let $i := string($rep/@xml:id)

    let $inthisrepo := $reposByRepoId('https://betamasaheft.eu/' || $i)
     let $count := count($inthisrepo)
     return
    if($count=0) then () else
        <div class="w3-row">
        <div class="w3-col" style="width:30%"><h4><a href="{$config:appUrl}/manuscripts/{$i}/list">{$rep/text()}</a></h4></div>
        <div class="w3-col" style="width:5%"><span class="w3-badge">{$count}</span></div>
          <div  class="w3-col" style="width:35%">
          <a class="w3-button w3-red"  onclick="openAccordion('list{$i}')">show list</a>
          <div class="w3-hide" id="list{$i}">
            {if($count gt 500) then (
            <div class="w3-card-4 w3-panel w3-gray w3-margin w3-padding">
                            <p class="w3-large">
                            There are too many manuscripts here. Please click on the repository link for the full list.
                                </p>
                                </div>
            ) else

                    for $m in $inthisrepo
                    let $collection := root($m)//t:collection
                        group by $C := $collection[1]
                        order by $C
                    return
                        <div class="w3-card-4 w3-panel w3-gray w3-margin w3-padding">
                            <p
                                class="w3-large">{$C}<span> </span> <span class="w3-badge w3-margin">{string(count($m))}</span></p>
                            <ul class="w3-ul w3-hoverable">{
                                    for $mcol in $m
                                    let $r := root($mcol)
                                    let $mainID := ($r//t:msIdentifier/t:idno)[1]/text()
                                    order by $mainID
                                    return
                                        <li><a
                                                href="{$config:appUrl}/{string-join($r/t:TEI/@xml:id)}">{string-join($r//t:msIdentifier//t:idno/text(), ', ')}</a></li>
                                }
                            </ul>
                        </div>

                }
            </div>
            </div>
        </div>
        }
        </div>
        }</div>
)
}
</div>

</div>
        {nav:footerNew()}

       <script type="text/javascript" src="resources/js/w3.js"/>
       <script type="text/javascript" src="resources/js/titles.js"/>
        </body>
        </html>
       )

        };



declare
%rest:GET
%rest:path("/BetMasWeb/Uni{$unitType}/browse")
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


{scriptlinks:scriptStyle()}
    </head>
    <body id="body">
        {nav:barNew()}
        {nav:modalsNew()}
<div class="w3-container w3-margin w3-padding-64">
<div class="w3-main" id="result" data-value="{$unitType}"/>
<script type="application/javascript" src="resources/js/UnitList.js"/>
</div>
        {nav:footerNew()}

       <script type="text/javascript" src="resources/js/w3.js"/>
        <script type="text/javascript" src="resources/js/titles.js"/>
        </body>
        </html>
       )

        };


        declare
        %rest:GET
%rest:path("/BetMasWeb/art-themes/list")
%rest:query-param("keyword", "{$keyword}", "")
%output:method("html5")
        function list:artthemes(
$keyword as xs:string*){
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
        <link rel="shortcut icon" href="{$config:appUrl}/resources/images/minilogo.ico"></link>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"></meta>
        {$list:app-meta}
       {scriptlinks:listScriptStyle()}
    </head>
    <body id="body">
        {nav:barNew()}
        {nav:modalsNew()}

 <div id="content" class="w3-container w3-padding-64 w3-margin">
        <div class="w3-container">
 <div class="w3-container w3-quarter w3-animate-left w3-padding "  data-hint="The values listed here all come from the taxonomy. Click on one of them to see which entities point to it.">
{
 let $collection := 'authority-files' return
 for $MainCat in $list:taxonomy//t:category[not(parent::t:category)][t:desc='Art Themes' or t:desc= 'Art Keywords' or t:desc = 'Objects and Animals']
 let $MainCatval := $MainCat/t:desc/text()
 order by replace(lower-case($MainCatval), '\s', '')
 return
 <div class="w3-panel w3-padding">
     <button class="w3-bar-item w3-button w3-red"
        onclick="openAccordion('list{replace($MainCatval, '\s', '')}')">{$MainCatval}
        <span class="w3-badge w3-margin-left">{count($MainCat/t:category)}</span>
    </button>
   <div id="list{replace($MainCatval, '\s', '')}" class="w3-hide">
      <ul class="w3-ul w3-hoverable">{
        for $subcat in $MainCat/t:category
        let $subcatid := string($subcat/@xml:id)
        order by replace(lower-case($subcat/t:*[1]/text()), '\s', '')
        return
           if($subcat/t:desc)
             then (let $subval := $subcat/t:desc
                  return (
                          <button class="w3-button  w3-gray w3-margin-top"
                          onclick="openAccordion('list{$subval}')">{$subval}
                          <span class="w3-badge  w3-margin-left">{count($subcat/t:category)}</span></button>,
                          <br/>,
                          <div id="list{$subval}" class="w3-hide">
                         <ul class="w3-ul w3-hoverable">
                         {for $c in  $subcat/t:category
                         let $subcatid := string($c/@xml:id)
                         let $text := $c/t:catDesc/text()
                         order by $text
                         return <li><a href="{$config:appUrl}/art-themes/list?keyword={$subcatid}">{$text}</a></li>
                        }</ul>
                        </div> ) )
             else
                 let $sstext := $subcat/t:catDesc/text()
                 order by $sstext
                 return
                     if ($subcat/t:category)
                      then (
                            <div class="w3-container w3-margin-top">
                             <button class="w3-button w3-gray"
                             onclick="openAccordion('list{$sstext}')">{$sstext}
                             <span class="w3-badge  w3-margin-left">{count($subcat/t:category)}</span></button>
                             <br/>
                             <div id="list{$sstext}" class="w3-hide">
                             <ul class="w3-ul w3-hoverable">{
                                 for $subsubcat in $subcat/t:category
                                 let $ssid := string($subsubcat/@xml:id)
                                 let $stext := $subsubcat/t:catDesc/text()
                                 order by $stext
                                 return
                                     <li><a href="{$config:appUrl}/art-themes/list?keyword={$ssid}">{$stext}</a></li>
                             }</ul>
                             </div>
                             </div>)
                    else(<li><a href="{$config:appUrl}/art-themes/list?keyword={$subcatid}">{$sstext}</a></li>)
 }
 </ul>
 </div>
 </div>}

 </div>
 <div class="w3-threequarter w3-container w3-padding" id="main" >
 {if($keyword = '')
 then (<div class="w3-panel w3-gray w3-card-4">Select an entry on the left to see all records where this occurs.</div>)
 else (
 let $res :=
 let $keywordlink := ('https://betamasaheft.eu/' || string($keyword))
 let $terms := $apprest:collection-root/t:TEI[descendant::t:term[@key eq  $keyword]]
 let $title := $apprest:collection-root/t:TEI[descendant::t:title[contains(@type,  $keyword)]]
 let $person := $apprest:collection-root/t:TEI[descendant::t:person[contains(@type,  $keyword)]]
 let $desc := $apprest:collection-root/t:TEI[descendant::t:desc[contains(@type,  $keyword)]]
 let $place := $apprest:collection-root/t:TEI[descendant::t:place[contains(@type,  $keyword)]]
 let $ab := $apprest:collection-root/t:TEI[descendant::t:ab[contains(@type,  $keyword)]]
 let $abc := $apprest:collection-root/t:TEI[descendant::t:ab[@corresp eq  $keywordlink]]
 let $rela := $apprest:collection-root/t:TEI[descendant::t:relation[@active eq  $keyword]]
 let $relp := $apprest:collection-root/t:TEI[descendant::t:relation[@passive eq $keyword]]
 let $rella := $apprest:collection-root/t:TEI[descendant::t:relation[@active eq  $keywordlink]]
 let $rellp := $apprest:collection-root/t:TEI[descendant::t:relation[@passive eq $keywordlink]]
 let $faith := $apprest:collection-root/t:TEI[descendant::t:faith[contains(@type,  $keyword)]]
 let $occupation := $apprest:collection-root/t:TEI[descendant::t:occupation[contains(@type,  $keyword)]]
 let $refb := $apprest:collection-root/t:TEI[descendant::t:ref[@corresp eq $keywordlink]]
 let $hits := ($terms |$title |$person |$desc |$place |$ab |$abc |$faith  |$occupation |$refb |$rela |$relp |$rella |$rellp)
   return
                      map {
                      'hits' : $hits,
                      'collection' : 'authority-files'
                      }

   return
 <div class="w3-container">
 <h1><a href="{$config:appUrl}/authority-files/{$keyword}/main">{exptit:printTitleID($keyword)}</a></h1>
 {let $file := $list:taxonomy/id($keyword)
 for $element in ($file//t:abstract, $file//t:listBibl)
 return <p>{string:tei2string($element)}</p>}

  <div class="w3-bar">
  <div id="hit-count" class="w3-bar-item">
   {'There are ' || count($res("hits")) || ' resources that contain the exact keyword: '}  <span class="w3-tag w3-red"><a href="{$config:appUrl}/{$keyword}">{$keyword}</a></span>
   </div>
   </div>
   <div class="w3-responsive">
    <table class="w3-table w3--hoverable"><thead><tr class="w3-tiny"><th>id</th><th>title</th><th>type</th></tr></thead><tbody>{for $h in $res("hits") return <tr><td>{string($h/@xml:id)}</td><td><a href="{$config:appUrl}/{string($h/@xml:id)}">{try{exptit:printTitleID($h/@xml:id)} catch * {util:log('info',string($h/@xml:id))}}</a></td><td>{string($h/@type)}</td></tr>}</tbody></table>
   </div>
                   </div>                 ) }
 </div>
 </div>

</div>

        {nav:footerNew()}

       <script type="text/javascript" src="resources/js/w3.js"/>
    </body>
</html>
        };

declare
%rest:GET
%rest:path("/BetMasWeb/{$collection}/list")
%rest:query-param("start", "{$start}", 1)
%rest:query-param("keyword", "{$keyword}", "")
%rest:query-param("mainname", "{$mainname}", "")
%rest:query-param("language", "{$language}", "")
%rest:query-param("prms", "{$prms}", "")
%rest:query-param("per-page", "{$per-page}", 20)
%rest:query-param("date-range", "{$date-range}", "")
%rest:query-param("clavisID", "{$clavisID}", "")
%rest:query-param("CAeID", "{$CAeID}", "")
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
%rest:query-param("bindingtype","{$bindingtype}", "")
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
$CAeID as xs:string*,
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
$bindingtype as xs:string* ,
$country as xs:string* ,
$settlement as xs:string* ,
$prms as xs:string*) {
let $c := $config:data-root||'/' || $collection
let $log := log:add-log-message('/'||$collection||'/list', sm:id()//sm:real/sm:username/string() , 'list')
let $Cmap := map {'type': 'collection', 'name' : $collection, 'path' : $c}
let $parameters :=
map{'key': $keyword,
'mainname': $mainname,
                           'lang': $language,
                           'date': $date-range,
                           'clavisID': $clavisID,
                           'CAeID': $CAeID,
                           'clavistype': $clavistype,
                           'cp': $cp,
                           'numberOfParts': $numberOfParts,
                           'height': $height,
'width': $width,
'depth': $depth,
'columnsNum': $columnsNum,
'tmargin': $tmargin,
'bmargin': $bmargin,
'rmargin': $rmargin,
'lmargin': $lmargin,
'intercolumn': $intercolumn,
'folia': $folia,
'qn': $qn,
'qcn': $qcn,
'wL': $wL,
'script': $script,
'scribe': $scribe,
'donor': $donor,
'patron': $patron,
'owner': $owner,
'binder': $binder,
'parchmentMaker': $parchmentMaker,
'objectType': $objectType,
'material': $material,
'bmaterial': $bmaterial,
'contents': $contents,
'origPlace': $origPlace,
'tabot':$tabot,
'placetype': $placetype,
'authors': $authors,
'occupation': $occupation,
'faith': $faith,
'gender': $gender,
'period': $period,
'restorations': $restorations,
'bindingtype': $bindingtype,
'country': $country,
'settlement': $settlement
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
        <link rel="shortcut icon" href="{$config:appUrl}/resources/images/minilogo.ico"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        {$list:app-meta}
        {scriptlinks:listScriptStyle()}
    </head>
    <body id="body">
        {nav:barNew()}
        {nav:modalsNew()}

 <div id="content" class="w3-container w3-padding-64 w3-margin">
 {if($collection = 'authority-files')
 then
 <div class="w3-container">
 <div class="w3-container w3-quarter w3-animate-left w3-padding "  data-hint="The values listed here all come from the taxonomy. Click on one of them to see which entities point to it.">
{for $MainCat in $list:taxonomy//t:category[not(parent::t:category)]
 let $collection := 'authority-files'
 let $MainCatval := $MainCat/t:desc/text()
 order by replace(lower-case($MainCatval), '\s', '')
 return
 <div class="w3-panel w3-padding">
     <button class="w3-bar-item w3-button w3-red"
        onclick="openAccordion('list{replace($MainCatval, '\s', '')}')">{$MainCatval}
        <span class="w3-badge w3-margin-left">{count($MainCat/t:category)}</span>
    </button>
   <div id="list{replace($MainCatval, '\s', '')}" class="w3-hide">
      <ul class="w3-ul w3-hoverable">{
        for $subcat in $MainCat/t:category
        let $subcatid := string($subcat/@xml:id)
        order by replace(lower-case($subcat/t:*[1]/text()), '\s', '')
        return
           if($subcat/t:desc)
             then (let $subval := $subcat/t:desc
                  return (
                          <button class="w3-button  w3-gray w3-margin-top"
                          onclick="openAccordion('list{$subval}')">{$subval}
                          <span class="w3-badge  w3-margin-left">{count($subcat/t:category)}</span></button>,
                          <br/>,
                          <div id="list{$subval}" class="w3-hide">
                         <ul class="w3-ul w3-hoverable">
                         {for $c in  $subcat/t:category
                         let $subcatid := string($c/@xml:id)
                         let $text := $c/t:catDesc/text()
                         order by $text
                         return <li><a href="{$config:appUrl}/{$collection}/list?keyword={$subcatid}">{$text}</a></li>
                        }</ul>
                        </div> ) )
             else
                 let $sstext := $subcat/t:catDesc/text()
                 order by $sstext
                 return
                     if ($subcat/t:category)
                      then (
                            <div class="w3-container w3-margin-top">
                             <button class="w3-button w3-gray"
                             onclick="openAccordion('list{$sstext}')">{$sstext}
                             <span class="w3-badge  w3-margin-left">{count($subcat/t:category)}</span></button>
                             <br/>
                             <div id="list{$sstext}" class="w3-hide">
                             <ul class="w3-ul w3-hoverable">{
                                 for $subsubcat in $subcat/t:category
                                 let $ssid := string($subsubcat/@xml:id)
                                 let $stext := $subsubcat/t:catDesc/text()
                                 order by $stext
                                 return
                                     <li><a href="{$config:appUrl}/{$collection}/list?keyword={$ssid}">{$stext}</a></li>,
                                     <ul>                                     {for $sss in $subcat/t:category/t:category
                                 let $sssid := string($sss/@xml:id)
                                 let $ssstext := concat($sss/ancestor::t:category[1]/t:catDesc/text(), ': ', $sss/t:catDesc/text())
                                     return

                                     <li><a href="{$config:appUrl}/{$collection}/list?keyword={$sssid}">{$ssstext}</a></li>
                                     }</ul>
                             }</ul>
                             </div>
                             </div>)
                    else(<li><a href="{$config:appUrl}/{$collection}/list?keyword={$subcatid}">{$sstext}</a></li>)
 }
 </ul>
 </div>
 </div>}


   {apptable:nextID($collection)}
 </div>
 <div class="w3-threequarter w3-container w3-padding" id="main" >
 {if($keyword = '')
 then (<div class="w3-panel w3-gray w3-card-4">Select an entry on the left to see all records where this occurs.</div>)
 else (
 let $res :=
 let $keywordlink := ('https://betamasaheft.eu/' || string($keyword))
 let $terms := $apprest:collection-root/t:TEI[descendant::t:term[@key eq  $keyword]]
 let $title := $apprest:collection-root/t:TEI[descendant::t:title[contains(@type,  $keyword)]]
 let $person := $apprest:collection-root/t:TEI[descendant::t:person[contains(@type,  $keyword)]]
 let $desc := $apprest:collection-root/t:TEI[descendant::t:desc[contains(@type,  $keyword)]]
 let $place := $apprest:collection-root/t:TEI[descendant::t:place[contains(@type,  $keyword)]]
 let $ab := $apprest:collection-root/t:TEI[descendant::t:ab[contains(@type,  $keyword)]]
 let $abc := $apprest:collection-root/t:TEI[descendant::t:ab[@corresp eq  $keywordlink]]
 let $rela := $apprest:collection-root/t:TEI[descendant::t:relation[@active eq  $keyword]]
 let $relp := $apprest:collection-root/t:TEI[descendant::t:relation[@passive eq $keyword]]
 let $rella := $apprest:collection-root/t:TEI[descendant::t:relation[@active eq  $keywordlink]]
 let $rellp := $apprest:collection-root/t:TEI[descendant::t:relation[@passive eq $keywordlink]]
 let $faith := $apprest:collection-root/t:TEI[descendant::t:faith[contains(@type,  $keyword)]]
 let $occupation := $apprest:collection-root/t:TEI[descendant::t:occupation[contains(@type,  $keyword)]]
 let $refb := $apprest:collection-root/t:TEI[descendant::t:ref[@corresp eq $keywordlink]]
 let $hits := ($terms |$title |$person |$desc |$place |$ab |$abc |$faith  |$occupation |$refb |$rela |$relp |$rella |$rellp)
 return
                      map {
                      'hits' : $hits,
                      'collection' : $collection
                      }

   return
 <div class="w3-container">
 <h1><a href="{$config:appUrl}/authority-files/{$keyword}/main">{exptit:printTitleID($keyword)}</a></h1>
 {let $file := $list:taxonomy/id($keyword)
 for $element in ($file//t:abstract, $file//t:listBibl)
 return <p>{string:tei2string($element)}</p>}

  <div class="w3-bar">
  <div id="hit-count" class="w3-bar-item">
   {'There are ' || count($res("hits")) || ' resources that contain the exact keyword: '}  <span class="w3-tag w3-red">{$keyword}</span>
   </div>
   </div>
   <div class="w3-responsive">
    <table class="w3-table w3--hoverable"><thead><tr class="w3-tiny"><th>id</th><th>title</th><th>type</th></tr></thead><tbody>{for $h in $res("hits") return <tr><td>{string($h/@xml:id)}</td><td><a href="{$config:appUrl}/{string($h/@xml:id)}">{try{exptit:printTitleID($h/@xml:id)} catch * {util:log('info',string($h/@xml:id))}}</a></td><td>{string($h/@type)}</td></tr>}</tbody></table>
   </div>
                   </div>                 ) }
 </div>
 </div>

 else
         let $parametersLenght := map:for-each($parameters, function($key, $value){if($value = '') then 0 else 1})
         return
        if(sum($parametersLenght) ge 1 ) then
        let $hits := apprest:listrest('collection', $collection, $parameters, $prms)
                return
<div class="w3-container">
    <div class="w3-panel w3-margin-bottom w3-card-4" id="listTopInfo">
   <div class="w3-bar">
   <div id="hit-count" class="w3-bar-item">
   {'There are '}
   <span class="w3-tag w3-gray">{count($hits("hits")) }</span>
   {  ' records in this selection of ' || $collection }
   </div>
   <div   id="optionsList">
   {
   if($collection = 'manuscripts') then ( if(count($hits("hits")) lt 1050) then
 (<a  target="_blank" class="w3-button w3-bar-item w3-red"
href="{replace(substring-after(rest:uri(), 'BetMas'), 'list', 'listChart')}?{exreq:query()}">Charts</a>)
else (<a  target="_blank"  disabled="disabled" class="w3-button w3-bar-item w3-red"
href="{replace(substring-after(rest:uri(), 'BetMas'), 'list', 'listChart')}?{exreq:query()}">Charts</a>)
) else ()}
{if ($collection = 'works')
   then
   let $texts :=  $hits('hits')[descendant::t:div[@type eq 'edition']//t:ab//text()]
   return
   if(count($texts) lt 100) then
  let $ids := for $hit in $texts return 'input=https://betamasaheft.eu/works/'||string($hit/@xml:id)||'.xml'
  let $urls := string-join($ids,'&amp;')
   return
   <a target="_blank" class="w3-button w3-bar-item w3-red" href="http://voyant-tools.org/?{$urls}">Voyant</a>
  else if (count($texts) eq 0) then
  (<span class="w3-button w3-bar-item w3-red" disabled="disabled" data-hint="No text available for analysis with Voyant Tools for this selection.">Voyant</span>)
  else (<span class="w3-button w3-bar-item w3-red" data-hint="With less than 100 hits, you will find here a button to analyse the available texts in your selection with Voyant Tools.">Voyant</span>)
        else ()   }

 <a class="w3-button w3-bar-item w3-gray" href="javascript:void(0);" onclick="javascript:introJs().addHints();">hints</a>

{apptable:nextID($collection)}
</div>
</div>

{if(count($parameters) gt 1) then list:paramsList($parameters) else ()}
</div>
    <div class="w3-quarter">
    {apprest:searchFilter-rest($collection, $hits)}
    {switch($collection)
    case 'manuscripts' return (apprest:institutions(),apprest:catalogues())
    default return ()}
    </div>
    <div class="w3-threequarter">
   <div class="w3-row w3-left">
    {apprest:paginate-rest($hits, $parameters, $start, $per-page, 5, 21)}
 </div>
    <div class="row">
    {apptable:table($hits, $start, $per-page)}
    </div>
<div class="w3-row w3-left">
    {apprest:paginate-rest($hits, $parameters, $start, $per-page, 9, 21)}
  </div>
</div>
</div>
        else
        <div class="w3-container">
        <div class="w3-quarter" data-hint="The following filters can be applied by clicking on the filter icon below, to return to the full list, click the list, to go to advanced search the cog">
    {
    let $collect := switch2:collection($collection)
    return
    apprest:searchFilter-rest($collection, map{'hits' : <start/>, 'query' : $collect})}
    {switch($collection)
    case 'manuscripts' return (apprest:institutions(),apprest:catalogues())
    default return ()}
    </div>
    <div class="w3-threequarter w3-panel w3-padding w3-red">Please, select a filter.</div>
    </div>
        }

</div>

        {nav:footerNew()}

       <script type="text/javascript" src="resources/js/w3.js"/>
        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/intro.js/2.9.3/intro.js"  ></script>
       <script type="text/javascript" src="resources/js/printgroupbutton.js"/>
       <script type="text/javascript" src="resources/js/printgroup.js"/>
        <script type="text/javascript" src="resources/js/toogle.js"/>
        <script type="text/javascript" src="resources/js/titles.js"/>
        <script type="text/javascript" src="resources/js/clavisid.js"/>
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
%rest:path("/BetMasWeb/manuscripts/listChart")
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
%rest:query-param("bindingtype","{$bindingtype}", "")
%rest:query-param("country","{$country}", "")
%rest:query-param("settlement","{$settlement}", "")
%output:method("html5")
function list:getlistChart(
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
$bindingtype as xs:string* ,
$country as xs:string* ,
$settlement as xs:string* ,
$prms as xs:string*) {
let $c := $config:data-root || '/'
let $log := log:add-log-message('/'||'manuscripts'||'/list', sm:id()//sm:real/sm:username/string() , 'list')
let $Cmap := map {'type': 'collection', 'name' : 'manuscripts', 'path' : $c}
let $parameters :=
map{'key': $keyword,
'mainname': $mainname,
                           'lang': $language,
                           'date': $date-range,
                           'clavisID': $clavisID,
                           'clavistype': $clavistype,
                           'cp': $cp,
                           'numberOfParts': $numberOfParts,
                           'height': $height,
'width': $width,
'depth': $depth,
'columnsNum': $columnsNum,
'tmargin': $tmargin,
'bmargin': $bmargin,
'rmargin': $rmargin,
'lmargin': $lmargin,
'intercolumn': $intercolumn,
'folia': $folia,
'qn': $qn,
'qcn': $qcn,
'wL': $wL,
'script': $script,
'scribe': $scribe,
'donor': $donor,
'patron': $patron,
'owner': $owner,
'binder': $binder,
'parchmentMaker': $parchmentMaker,
'objectType': $objectType,
'material': $material,
'bmaterial': $bmaterial,
'contents': $contents,
'origPlace': $origPlace,
'tabot': $tabot,
'placetype': $placetype,
'authors': $authors,
'occupation': $occupation,
'faith': $faith,
'gender': $gender,
'period': $period,
'restorations': $restorations,
'bindingtype': $bindingtype,
'country': $country,
'settlement': $settlement
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
        <link rel="shortcut icon" href="{$config:appUrl}/resources/images/minilogo.ico"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        {$list:app-meta}
{scriptlinks:scriptStyle()}
<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"/>
    </head>
     <body id="body">
        {nav:barNew()}
        {nav:modalsNew()}

       {let $hits := apprest:listrest('collection', 'manuscripts', $parameters, $prms)
    return

   <div class="w3-container w3-margin w3-padding-64">
   <div class="w3-panel w3-margin-bottom w3-card-4" id="listTopInfo">
   <div class="w3-bar">
   <div id="hit-count" class="w3-bar-item">
   {'There are '}
   <span class="w3-tag w3-gray">{count($hits("hits")) }</span>
   { ' manuscripts in this search ' }
   </div>
   <div   id="optionsList">
   <a  target="_blank"  class="w3-bar-item w3-button w3-red" href="{$config:appUrl}/{replace(substring-after(rest:uri(), 'BetMas'), 'listChart', 'list')}?{exreq:query()}">List</a></div>
   </div>
   {if(count($parameters) gt 1) then list:paramsList($parameters) else ()}
   </div>

   <div class="w3-container w3-margin w3-padding">
   {charts:chart($hits("hits"))}
   </div>
</div>
        }

        {nav:footerNew()}

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
%rest:path("/BetMasWeb/manuscripts/{$repoID}/list")
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
let $repos := $config:data-rootIn||'/'
let $log := log:add-log-message('/manuscripts/'||$repoID||'/list', sm:id()//sm:real/sm:username/string() , 'list')
let $Cmap := map {'type': 'repo', 'name' : $repoID, 'path' : $repos}
let $parameters := map{'key': $keyword,
'lang': $language,'date': $date-range,'numberOfParts': $numberOfParts,  'height': $height,

'mainname': $mainname,
'width': $width,
'depth': $depth,
'columnsNum': $columnsNum,
'tmargin': $tmargin,
'bmargin': $bmargin,
'rmargin': $rmargin,
'lmargin': $lmargin,
'intercolumn': $intercolumn,
'folia': $folia,
'qn': $qn,
'qcn': $qcn,
'wL': $wL,
'script': $script,
'scribe': $scribe,
'donor': $donor,
'patron': $patron,
'owner': $owner,
'binder': $binder,
'parchmentMaker': $parchmentMaker,
'objectType': $objectType,
'material': $material,
'bmaterial': $bmaterial,
'contents': $contents,
'origPlace': $origPlace}
let $file := $apprest:collection-rootIn//id($repoID)[self::t:TEI]
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
        <link rel="shortcut icon" href="{$config:appUrl}/resources/images/minilogo.ico"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        {$list:app-meta}

        <link rel="stylesheet" type="text/css" href="{$config:appUrl}/resources/css/mapbox.css"/>
        <link rel="stylesheet" type="text/css" href="{$config:appUrl}/resources/css/leaflet.css"/>
        <link  rel="stylesheet" type="text/css" href="{$config:appUrl}/resources/css/leaflet.fullscreen.css"/>
        <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="{$config:appUrl}/resources/css/leaflet-search.css"/>
        {scriptlinks:listScriptStyle()}
       <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/leaflet.js"/>
        <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="{$config:appUrl}/resources/js/mapbox.js"/>
        <script  xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="{$config:appUrl}/resources/js/Leaflet.fullscreen.min.js"/>
        <script  xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="{$config:appUrl}/resources/js/leaflet-search.js"/>
         <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="{$config:appUrl}/resources/js/leaflet-ajax-gh-pages/dist/leaflet.ajax.min.js"></script>

    </head>
    <body id="body">
        {nav:barNew()}
        {nav:modalsNew()}
<div class="w3-main w3-container w3-margin w3-padding-64">

<div class="w3-quarter w3-hide-small">
       {item2:RestItem($file, 'institutions')}
       <div class="w3-container w3-padding">
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


 {let $hits := apprest:listrest('repo', $repoID, $parameters, $prms)
    return
    <div id="content" class="w3-threequarter">
   <div class="w3-panel w3-margin-bottom w3-card-4" id="listTopInfo">
   <div class="w3-bar">
   <div id="hit-count" class="w3-bar-item">
   {'There are '}
   <span class="w3-tag w3-gray">{count($hits("hits")) }</span>
   { ' manuscripts at ' || exptit:printTitleID($repoID) }
   </div>
   <div   id="optionsList">
<a target="_blank" class="w3-button w3-bar-item w3-red"
href="{$config:appUrl}/manuscripts/{$repoID}/list/viewer">Images</a>
<a  target="_blank"  role="button" class="w3-button w3-bar-item w3-red"
href="{replace(substring-after(rest:uri(), 'BetMas'), 'list', 'listChart')}?{exreq:query()}">Charts</a>
<a class="w3-button w3-bar-item w3-gray" href="javascript:void(0);" onclick="javascript:introJs().addHints();">hints</a>
{apptable:nextID('manuscripts')}
</div>
</div>

{if(count($parameters) gt 1) then list:paramsList($parameters) else ()}
</div>
    <div class="w3-threequarter">

   <div class="w3-row w3-left">
    {apprest:paginate-rest($hits, $parameters, $start, $per-page, 9, 21)}
     </div>
<div class="w3-row">
    {apptable:table($hits, $start, $per-page)}
    </div>
      <div class="w3-row w3-left">
    {apprest:paginate-rest($hits, $parameters, $start, $per-page, 9, 21)}
                   </div>



        </div>

    <div class="w3-quarter w3-white w3-hide-small w3-hide-medium" id="search filters">
    {apprest:searchFilter-rest($repoID, $hits)}
    <div class="w3-container"><a class="w3-button w3-large w3-red w3-margin-left" href="{$config:appUrl}/manuscripts/list">Back to full list</a></div>
    </div>

 </div>
  }


<div class="w3-container w3-margin">
<div class="w3-panel w3-card-4 w3-margin-top w3-padding">The information below is about the institution record, for the manuscript catalogue records, please see the specific information provided with each record.</div>
{ apprest:authors($file, 'institutions')}

</div>

</div>
        {nav:footerNew()}

        <script type="text/javascript" src="resources/js/w3.js"/>
        <script type="application/javascript" src="resources/js/introText.js"/>
       <script type="text/javascript" src="resources/js/printgroupbutton.js"/>
       <script type="text/javascript" src="resources/js/printgroup.js"/>
        <script type="text/javascript" src="resources/js/toogle.js"/>
        <script type="text/javascript" src="resources/js/titles.js"/>
        <script type="text/javascript" src="resources/js/clavisid.js"/>
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
%rest:path("/BetMasWeb/manuscripts/{$repoID}/listChart")
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
function list:getrepolistchart(
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
let $repos := $config:data-rootIn||'/'
let $log := log:add-log-message('/manuscripts/'||$repoID||'/list', sm:id()//sm:real/sm:username/string() , 'list')
let $Cmap := map {'type':  'repo', 'name' : $repoID, 'path' :  $repos}
let $parameters := map{'key': $keyword,
'lang': $language,'date': $date-range,'numberOfParts': $numberOfParts,  'height': $height,

'mainname': $mainname,
'width': $width,
'depth': $depth,
'columnsNum': $columnsNum,
'tmargin': $tmargin,
'bmargin': $bmargin,
'rmargin': $rmargin,
'lmargin': $lmargin,
'intercolumn': $intercolumn,
'folia': $folia,
'qn': $qn,
'qcn': $qcn,
'wL': $wL,
'script': $script,
'scribe': $scribe,
'donor': $donor,
'patron': $patron,
'owner': $owner,
'binder': $binder,
'parchmentMaker': $parchmentMaker,
'objectType': $objectType,
'material': $material,
'bmaterial': $bmaterial,
'contents': $contents,
'origPlace': $origPlace}
let $file := $apprest:collection-rootIn//id($repoID)[self::t:TEI]
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
        <link rel="shortcut icon" href="{$config:appUrl}/resources/images/minilogo.ico"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        {$list:app-meta}
{scriptlinks:scriptStyle()}
<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"/>
    </head>
    <body id="body">
        {nav:barNew()}
        {nav:modalsNew()}

 {let $hits := apprest:listrest('repo', $repoID, $parameters, $prms)
    return

   <div class="w3-container w3-margin w3-padding-64">
   <div class="w3-panel w3-margin-bottom w3-card-4" id="listTopInfo">
   <div class="w3-bar">
   <div id="hit-count" class="w3-bar-item">
   {'There are '}
   <span class="w3-tag w3-gray">{count($hits("hits")) }</span>
   { ' manuscripts at ' || exptit:printTitleID($repoID) }
   </div>
   <div   id="optionsList">
   <a  target="_blank"  class="w3-bar-item w3-button w3-red" href="{replace(substring-after(rest:uri(), 'BetMas'), 'listChart', 'list')}?{exreq:query()}">List</a></div>
   <a target="_blank" class="w3-bar-item w3-button w3-red" href="{$config:appUrl}/manuscripts/{$repoID}/list/viewer">Images</a>
   </div>
   {if(count($parameters) gt 1) then list:paramsList($parameters) else ()}
   </div>

   <div class="w3-container w3-margin w3-padding">
   {charts:chart($hits("hits"))}
   </div>
</div>
        }

        {nav:footerNew()}

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
%rest:path("/BetMasWeb/manuscripts/place/list")
%rest:query-param("start", "{$start}", 1)
%rest:query-param("place", "{$place}", "")
%rest:query-param("per-page", "{$per-page}", 20)
%rest:query-param("keyword", "{$keyword}", "")
%rest:query-param("mainname", "{$mainname}", "")
%rest:query-param("language", "{$language}", "")
%rest:query-param("prms", "{$prms}", "")
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
function list:getplacelist(
$place as xs:string*,
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
let $repos := $config:data-rootIn||'/'
let $log := log:add-log-message('/manuscripts/place/list', sm:id()//sm:real/sm:username/string() , 'list')
let $Cmap := map {'type': 'place', 'name' : $place, 'path' :  $repos}
let $parameters := map{'key': $keyword,
'lang': $language,'date': $date-range,'numberOfParts': $numberOfParts,  'height': $height,

'mainname': $mainname,
'width': $width,
'depth': $depth,
'columnsNum': $columnsNum,
'tmargin': $tmargin,
'bmargin': $bmargin,
'rmargin': $rmargin,
'lmargin': $lmargin,
'intercolumn': $intercolumn,
'folia': $folia,
'qn': $qn,
'qcn': $qcn,
'wL': $wL,
'script': $script,
'scribe': $scribe,
'donor': $donor,
'patron': $patron,
'owner': $owner,
'binder': $binder,
'parchmentMaker': $parchmentMaker,
'objectType': $objectType,
'material': $material,
'bmaterial': $bmaterial,
'contents': $contents,
'origPlace': $origPlace}
let $file := $apprest:collection-rootPlIn//id($place)[self::t:TEI]
let $sameAs := string($file//t:place/@sameAs)
return


if($file or starts-with($place, 'wd:')) then (
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
        <link rel="shortcut icon" href="{$config:appUrl}/resources/images/minilogo.ico"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        {$list:app-meta}

        <link rel="stylesheet" type="text/css" href="{$config:appUrl}/resources/css/mapbox.css"/>
        <link rel="stylesheet" type="text/css" href="{$config:appUrl}/resources/css/leaflet.css"/>
        <link  rel="stylesheet" type="text/css" href="{$config:appUrl}/resources/css/leaflet.fullscreen.css"/>
        <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="{$config:appUrl}/resources/css/leaflet-search.css"/>
        {scriptlinks:listScriptStyle()}
       <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/leaflet.js"/>
        <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="resources/js/mapbox.js"/>
        <script  xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="resources/js/Leaflet.fullscreen.min.js"/>
        <script  xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="resources/js/leaflet-search.js"/>
         <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="resources/js/leaflet-ajax-gh-pages/dist/leaflet.ajax.min.js"></script>

    </head>
    <body id="body">
        {nav:barNew()}
        {nav:modalsNew()}
<div class="w3-main w3-container w3-margin w3-padding-64">

<div class="w3-quarter w3-hide-small">
       <h1>Manuscripts in {exptit:printTitleID($place)}</h1>
       <span class="w3-tag w3-gray">{$config:appUrl||'/'||$place}</span>
       <div class="w3-container w3-padding">
       <iframe
   style="border:none;"
                allowfullscreen="true"
                width="100%"
                height="400"
                src="https://peripleo.pelagios.org/embed/{encode-for-uri(concat('http://betamasaheft.eu/places/',$place))}">
            </iframe>
       <div id="entitymap" style="width: 100%; height: 400px; margin-top:100px" />
   <script>{'var placeid = "'||$place||'"'}</script>
   <script  type="text/javascript" src="resources/geo/geojsonentitymap.js"></script></div>

        {apprest:EntityRelsTable($file, 'places')}

       </div>


 {let $allrepositories := for $repo in ($apprest:collection-rootIn//t:settlement[@ref eq $place],
                                        $apprest:collection-rootIn//t:region[@ref eq $place],
                                        $apprest:collection-rootIn//t:country[@ref eq $place],
                                        $apprest:collection-rootIn//t:settlement[@ref eq $sameAs],
                                        $apprest:collection-rootIn//t:region[@ref eq $sameAs],
                                        $apprest:collection-rootIn//t:country[@ref eq $sameAs])
                          return $repo/ancestor::t:TEI/@xml:id
 let $repositoriesIDS := config:distinct-values($allrepositories)
 let $selected := if(count($repositoriesIDS) ge 1) then $apprest:collection-rootMS//t:repository[@ref eq  $repositoriesIDS] else ()
 let $allmssinregion := if(count($selected) ge 1 ) then (for $s in $selected return $s/ancestor::t:TEI) else 0
 let $stringquery := '$apprest:collection-rootMS//t:repository[@ref eq ("' || string-join($repositoriesIDS, '","') || '")]/ancestor::t:TEI'
let $hits :=
            map {
                      'hits' : $allmssinregion,
                      'collection' : 'manuscripts',
                      'query': $stringquery
                      }
    return
        if($hits("hits") = 0 ) then (
            <div id="content" class="w3-threequarter">
   <div class="w3-panel w3-margin-bottom w3-card-4" id="listTopInfo">
   <div class="w3-bar">
   <div id="hit-count" class="w3-bar-item">
   {'There are no manuscripts in ' || exptit:printTitleID($place) || ' or we simply do not have enough information to tell you, try another search please.'}
   </div>
   </div>
   </div>
   </div>
            )
        else
    <div id="content" class="w3-threequarter">
   <div class="w3-panel w3-margin-bottom w3-card-4" id="listTopInfo">
   <div class="w3-bar">
   <div id="hit-count" class="w3-bar-item">
   {'There are '}
   <span class="w3-tag w3-gray">{count($hits("hits")) }</span>
   { ' manuscripts in ' || exptit:printTitleID($place) }
   </div>

   <div   id="optionsList">
<a  target="_blank"  role="button" class="w3-button w3-bar-item w3-red"
href="{replace(substring-after(rest:uri(), 'BetMas'), 'list', 'listChart')}?{exreq:query()}">Charts</a>
<a class="w3-button w3-bar-item w3-gray" href="javascript:void(0);" onclick="javascript:introJs().addHints();">hints</a>
{apptable:nextID('manuscripts')}
</div>

   {if(count($parameters) gt 1) then list:paramsList($parameters) else ()}
</div>
</div>
    <div class="w3-threequarter">

   <div class="w3-row w3-left">
    {apprest:paginate-rest($hits, $parameters, $start, $per-page, 9, 21)}
     </div>
<div class="w3-row">
    {apptable:table($hits, $start, $per-page)}
    </div>
      <div class="w3-row w3-left">
    {apprest:paginate-rest($hits, $parameters, $start, $per-page, 9, 21)}
                   </div>



        </div>

    <div class="w3-quarter w3-white w3-hide-small w3-hide-medium" id="search filters">
    {apprest:searchFilter-rest($place, $hits)}
    <div class="w3-container"><a class="w3-button w3-large w3-red w3-margin-left" href="{$config:appUrl}/manuscripts/list">Back to full list</a></div>
    </div>

 </div>
  }


<div class="w3-container w3-margin">
<div class="w3-panel w3-card-4 w3-margin-top w3-padding">The information below is about the place record, for the manuscript catalogue records, please see the specific information provided with each record.</div>
{ apprest:authors($file, 'places')}

</div>

</div>
        {nav:footerNew()}

        <script type="text/javascript" src="resources/js/w3.js"/>
        <script type="application/javascript" src="resources/js/introText.js"/>
       <script type="text/javascript" src="resources/js/printgroupbutton.js"/>
       <script type="text/javascript" src="resources/js/printgroup.js"/>
        <script type="text/javascript" src="resources/js/toogle.js"/>
        <script type="text/javascript" src="resources/js/titles.js"/>
        <script type="text/javascript" src="resources/js/clavisid.js"/>
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
%rest:path("/BetMasWeb/manuscripts/place/listChart")
%rest:query-param("place", "{$place}", "")
%output:method("html5")
function list:getregionchart(
$place as xs:string*) {

(:the file for that institution:)
let $repos := $config:data-rootIn||'/'
let $log := log:add-log-message('/manuscripts/region/listChart', sm:id()//sm:real/sm:username/string() , 'list')
let $Cmap := map {'type':  'reporegion', 'name' : $place, 'path' : $repos}

let $file := $apprest:collection-rootPl//id($place)[self::t:TEI]
return


if($file or starts-with($place, 'wd:')) then (
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
        <link rel="shortcut icon" href="{$config:appUrl}/resources/images/minilogo.ico"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        {$list:app-meta}
{scriptlinks:scriptStyle()}
<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"/>
    </head>
    <body id="body">
        {nav:barNew()}
        {nav:modalsNew()}

 {
 let $allrepositories := for $repo in ($apprest:collection-rootIn//t:settlement[@ref eq $place],
 $apprest:collection-rootIn//t:region[@ref eq $place],
 $apprest:collection-rootIn//t:country[@ref eq $place])
 return $repo/ancestor::t:TEI/@xml:id
 let $repositoriesIDS := config:distinct-values($allrepositories)
 let $allmssinregion := $apprest:collection-rootMS//t:repository[@ref eq  $repositoriesIDS]/ancestor::t:TEI
 let $hits :=
            map {
                      'hits' : $allmssinregion
                      }
    return

   <div class="w3-container w3-margin w3-padding-64">
   <div class="w3-panel w3-margin-bottom w3-card-4" id="listTopInfo">
   <div class="w3-bar">
   <div id="hit-count" class="w3-bar-item">
   {'There are '}
   <span class="w3-tag w3-gray">{count($hits("hits")) }</span>
   { ' manuscripts in ' || exptit:printTitleID($place) }
   </div>
   <div   id="optionsList">
   <a  target="_blank"  class="w3-bar-item w3-button w3-red" href="{replace(substring-after(rest:uri(), 'BetMas'), 'listChart', 'list')}?{exreq:query()}">List</a></div>
   {if($file) then <a target="_blank" class="w3-bar-item w3-button w3-red" href="{$config:appUrl}/places/{$place}/main">Place record</a> else ()}
   </div>
   </div>

   <div class="w3-container w3-margin w3-padding">
   {charts:chart($hits("hits"))}
   </div>
</div>
        }
        {nav:footerNew()}
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
%rest:path("/BetMasWeb/catalogues/list")
%output:method("html5")
function list:getcatalogues() {
(log:add-log-message('/catalogues/list', sm:id()//sm:real/sm:username/string() , 'list'),
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
        <link rel="shortcut icon" href="{$config:appUrl}/resources/images/minilogo.ico"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        {$list:app-meta}
{scriptlinks:scriptStyle()}

    </head>
    <body id="body">
        {nav:barNew()}
        {nav:modalsNew()}
       {
         let $cats := $apprest:collection-rootMS//t:listBibl[@type eq 'catalogue']
       let $dist := config:distinct-values($cats//t:ptr/@target)
       return
       <div class="w3-container w3-margin w3-padding-64">


      <div class="w3-container">
    <h2><span class="w3-tag w3-gray">{count($dist)}</span> available catalogues</h2>

    <table class="w3-table w3-hoverable" max-width="100%">
    <tbody>
  {
   for $catalogue in $dist
   let $itemID := replace($catalogue, ':','_')
   let $zoTag := substring-after($catalogue, 'bm:')
   let $count := count($cats//t:ptr[@target eq $catalogue])
   let $xml-url := concat('https://api.zotero.org/groups/358366/items?&amp;tag=', $catalogue, '&amp;format=bib&amp;locale=en-GB&amp;style=hiob-ludolf-centre-for-ethiopian-studies')
   let $val := string($catalogue)
   let $entry := $list:bibliography//b:entry[@id=$val]

let $data :=
 if(count($entry) ge 1)
 then let $c := $entry
 return <span n="{count($c/preceding-sibling::t:item) +1}">{$c/*:reference/node() }</span>
 else  <span n="new">{let $request := <http:request href="{xs:anyURI($xml-url)}" method="GET"/>
    let $response := http:send-request($request)[2] return $response//div[@class eq "csl-bib-body"]/div/node()}</span>
 let $sorting := $data//text()[1]
order by $catalogue
return
    <tr>
    <td><a href="{$config:appUrl}/newSearch.html?searchType=text&amp;mode=any&amp;biblref={$catalogue}" class="lead">{$data}</a></td>
    <td><span class="w3-badge">{$count}</span></td>
    </tr>
    }
    </tbody></table>
    </div>
    <div class="w3-panel w3-red w3-card-4">More catalogues will be processed. A list of the catalogues to be processed and of the work in progress can be seen <a href="{$config:appUrl}/availableImages.html">here</a></div>


        </div>}
        {nav:footerNew()}
    </body>
</html>
)

};

declare
%rest:GET
%rest:path("/BetMasWeb/catalogues/{$catalogueID}/list")
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

let $log := log:add-log-message('/catalogues/'||$catalogueID||'/list', sm:id()//sm:real/sm:username/string() , 'list')
let $catalogues := for $catalogue in config:distinct-values($apprest:collection-rootMS//t:listBibl[@type eq 'catalogue']//t:ptr/@target)
	return $catalogue
	let $prefixedcatID := 'bm:' ||$catalogueID
let $Cmap := map {'type': 'catalogue', 'name' :  $catalogueID, 'path' :  $catalogues}
let $parameters := map{'key': $keyword,'lang': $language,'date': $date-range,'numberOfParts': $numberOfParts,  'height': $height,
'width': $width,
'depth': $depth,
'columnsNum': $columnsNum,
'tmargin': $tmargin,
'bmargin': $bmargin,
'rmargin': $rmargin,
'lmargin': $lmargin,
'intercolumn': $intercolumn,
'folia': $folia,
'qn': $qn,
'qcn': $qcn,
'wL': $wL,
'script': $script,
'scribe': $scribe,
'donor': $donor,
'patron': $patron,
'owner': $owner,
'binder': $binder,
'parchmentMaker': $parchmentMaker,
'objectType': $objectType,
'material': $material,
'bmaterial': $bmaterial,
'contents': $contents,
'origPlace': $origPlace}
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
        <link rel="shortcut icon" href="{$config:appUrl}/resources/images/minilogo.ico"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>

        {scriptlinks:listScriptStyle()}

        </head>
    <body id="body">
        {nav:barNew()}
        {nav:modalsNew()}
       <div class="w3-container w3-margin w3-padding-64">

      <h1>{
      let $itemID := replace($prefixedcatID, ':','_')
      let $xml-url := concat('https://api.zotero.org/groups/358366/items?&amp;tag=', $prefixedcatID, '&amp;format=bib&amp;locale=en-GB&amp;style=hiob-ludolf-centre-for-ethiopian-studies')
let $data :=  if($list:catalogues//t:item[@xml:id = $itemID])
 then <span n="{count($list:catalogues//t:item[@xml:id = $itemID]/preceding-sibling::t:item) +1}">{$list:catalogues//t:item[@xml:id = $itemID]/node() }</span>
 else  <span n="new">{let $request := <http:request href="{xs:anyURI($xml-url)}" method="GET"/>
   return http:send-request($request)[2]}</span>
return $data
}</h1>



 {let $hits := apprest:listrest('catalogue',$catalogueID, $parameters, $prms)
    return
   <div class="w3-container">
   <div class="w3-panel w3-margin-bottom w3-card-4" id="listTopInfo">
   <div class="w3-bar">
   <div id="hit-count" class="w3-bar-item">
   {'This catalogue has been quoted in '}
   <span class="w3-tag w3-gray">{count($hits("hits")) }</span>
   { ' manuscript records.'}
   </div>
   <div   id="optionsList">
<a  target="_blank"  role="button" class="w3-button w3-bar-item w3-red"
href="{replace(substring-after(rest:uri(), 'BetMas'), 'list', 'listChart')}?{exreq:query()}">Charts</a>
{apptable:nextID('manuscripts')}
</div>
</div>

{if(count($parameters) gt 1) then list:paramsList($parameters) else ()}
</div>




    <div class="w3-quarter w3-padding">
    {apprest:searchFilter-rest($catalogueID, $hits)}
     <div class="w3-quarter w3-margin w3-padding">
    <a  class="w3-button w3-red w3-margin-left" href="{$config:appUrl}/manuscripts/list">Back to full list</a>
    </div>
    </div>
    <div class="w3-threequarter w3-padding">
   <div class="w3-row w3-left">
    {apprest:paginate-rest($hits, $parameters, $start, $per-page, 5, 21)}
    </div>
    <div class="w3-row">{apptable:table($hits, $start, $per-page)}</div>
    <div class="w3-row w3-left">
    {apprest:paginate-rest($hits, $parameters, $start, $per-page, 5, 21)}
    </div>
    </div>
    </div>
      }
       </div>
       {nav:footerNew()}

       <script type="text/javascript" src="resources/js/w3.js"/>

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
%rest:path("/BetMasWeb/catalogues/{$catalogueID}/listChart")
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
function list:getcataloguelistChart(
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

let $log := log:add-log-message('/catalogues/'||$catalogueID||'/list', sm:id()//sm:real/sm:username/string() , 'list')
let $catalogues := for $catalogue in config:distinct-values($apprest:collection-rootMS//t:listBibl[@type eq 'catalogue']//t:ptr/@target)
	return $catalogue
	let $prefixedcatID := 'bm:' ||$catalogueID
let $Cmap := map {'type': 'catalogue', 'name' :  $catalogueID, 'path' : $catalogues}
let $parameters := map{'key': $keyword,'lang':$language,'date': $date-range,'numberOfParts':$numberOfParts,  'height':$height,
'width': $width,
'depth': $depth,
'columnsNum': $columnsNum,
'tmargin': $tmargin,
'bmargin': $bmargin,
'rmargin': $rmargin,
'lmargin': $lmargin,
'intercolumn': $intercolumn,
'folia': $folia,
'qn': $qn,
'qcn': $qcn,
'wL': $wL,
'script': $script,
'scribe': $scribe,
'donor': $donor,
'patron': $patron,
'owner': $owner,
'binder': $binder,
'parchmentMaker': $parchmentMaker,
'objectType': $objectType,
'material': $material,
'bmaterial': $bmaterial,
'contents': $contents,
'origPlace': $origPlace}
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
        <link rel="shortcut icon" href="{$config:appUrl}/resources/images/minilogo.ico"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        {$list:app-meta}
{scriptlinks:scriptStyle()}
<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"/>


    </head>
    <body id="body">
        {nav:barNew()}
        {nav:modalsNew()}
       <div class="w3-container w3-margin w3-padding-64">

      <h1>{
      let $itemID := replace($prefixedcatID, ':','_')
      let $xml-url := concat('https://api.zotero.org/groups/358366/items?&amp;tag=', $prefixedcatID, '&amp;format=bib&amp;locale=en-GB&amp;style=hiob-ludolf-centre-for-ethiopian-studies')
let $data := if($list:catalogues//t:item[@xml:id = $itemID])
 then <span n="{count($list:catalogues//t:item[@xml:id = $itemID]/preceding-sibling::t:item) +1}">{$list:catalogues//t:item[@xml:id = $itemID]/node() }</span>
 else  <span n="new">{let $request := <http:request href="{xs:anyURI($xml-url)}" method="GET"/>
    return http:send-request($request)[2]}</span>
return $data
}</h1>

 {let $hits := apprest:listrest('catalogue',$catalogueID, $parameters, $prms)
    return

    <div class="w3-container w3-margin w3-padding-64">
   <div class="w3-panel w3-margin-bottom w3-card-4" id="listTopInfo">
   <div class="w3-bar">
   <div id="hit-count" class="w3-bar-item">
    {'This catalogue has been quoted in '}
   <span class="w3-tag w3-gray">{count($hits("hits")) }</span>
   { ' manuscript records.'}
   </div>
   <div   id="optionsList">
   <a  target="_blank"  class="w3-bar-item w3-button w3-red" href="{replace(substring-after(rest:uri(), 'BetMas'), 'listChart', 'list')}?{exreq:query()}">List</a></div>
   </div>
   {if(count($parameters) gt 1) then list:paramsList($parameters) else ()}
   </div>

   <div class="w3-container w3-margin w3-padding">
   {charts:chart($hits("hits"))}
   </div>
</div>
}
        </div>
        {nav:footerNew()}

       <script type="text/javascript" src="resources/js/w3.js"/>
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
   <div class="w3-panel w3-card-4 w3-padding w3-margin-bottom">
   {map:for-each($parameters,
   function($key, $value) {
   if($value = '') then ()
   else  if ($key = 'date')
                     then (
                     if($value = '0,2000') then ()
   else <span class="w3-tag w3-small w3-gray">{'with a date (anywhere in the description) between ' || substring-before($value, ',') || ' and ' || substring-after($value, ',')}</span>)
   else  if ($key = 'wL')
                     then (if($value = '1,100') then ()
   else <span class="w3-tag w3-small w3-gray">{'between ' || substring-before($value, ',') || ' and ' || substring-after($value, ',')}</span>)
   else  if ($key = 'folia')
                     then (if($value = '1,1000') then ()
   else <span class="w3-tag w3-small w3-gray">{'between ' || substring-before($value, ',') || ' and ' || substring-after($value, ',') ||' leaves' }</span>)
   else  if ($key = 'qn')
                     then (if($value = '1,100') then ()
   else <span class="w3-tag w3-small w3-gray">{'between ' || substring-before($value, ',') || ' and ' || substring-after($value, ',') || ' quires in the manuscript'}</span>)
   else  if ($key = 'qcn')
                     then (if($value = '1,40') then ()
   else <span class="w3-tag w3-small w3-gray">{'between ' || substring-before($value, ',') || ' and ' || substring-after($value, ',') ||' leaves in at least one quire in the manuscript' }</span>)

   else
   <span class="w3-tag w3-small w3-gray">{$key|| ": ", <span class="w3-badge">{ $value }</span>}</span>})}
   </div>

};