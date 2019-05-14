xquery version "3.1" encoding "UTF-8";
(:~
 : template like RESTXQ module to generate the comparison page
 : 
 : @author Pietro Liuzzo 
 :)

module namespace workmap = "https://www.betamasaheft.uni-hamburg.de/BetMas/workmap";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMas/modules/log.xqm";
import module namespace app = "https://www.betamasaheft.uni-hamburg.de/BetMas/app" at "xmldb:exist:///db/apps/BetMas/modules/app.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMas/nav" at "xmldb:exist:///db/apps/BetMas/modules/nav.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMas/apprest" at "xmldb:exist:///db/apps/BetMas/modules/apprest.xqm";
import module namespace error = "https://www.betamasaheft.uni-hamburg.de/BetMas/error" at "xmldb:exist:///db/apps/BetMas/modules/error.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace coord = "https://www.betamasaheft.uni-hamburg.de/BetMas/coord" at "xmldb:exist:///db/apps/BetMas/modules/coordinates.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace ann = "https://www.betamasaheft.uni-hamburg.de/BetMas/ann" at "xmldb:exist:///db/apps/BetMas/modules/annotations.xqm";

declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace dcterms = "http://purl.org/dc/terms";
declare namespace saws = "http://purl.org/saws/ontology";
declare namespace cmd = "http://www.clarin.eu/cmd/";
declare namespace test="http://exist-db.org/xquery/xqsuite";

(: For REST annotations :)
declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";

declare variable $workmap:meta := <meta  xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $genauthor in $config:repo-descriptor/repo:author
    return
        <meta xmlns="http://www.w3.org/1999/xhtml" name="creator" content="{$genauthor/text()}"></meta>
        ;



declare 
%rest:GET
%rest:POST
%rest:path("/BetMas/workmap")
%rest:query-param("worksid", "{$worksid}", "")
%output:method("html5")
function workmap:workmap(
$worksid as xs:string*) {
let $fullurl := ('?worksid=' || $worksid)
let $log := log:add-log-message($fullurl, xmldb:get-current-user(), 'worksmap')
let $w :=  if(contains($worksid, ',')) then for $work in tokenize($worksid, ',') return $config:collection-rootW/id($work) else $config:collection-rootW/id($worksid)  
let $baseuris := for $bu in $w return base-uri($bu)
let $Cmap := map {'type':= 'item', 'name' := $worksid, 'path' := string-join($baseuris)}
let $kmlparam := for $work at $p in $w/@xml:id return  'kml'||$p||'=https://betamasaheft.eu/workmap/KML/'||string($work)
return
if(exists($w) or $worksid ='') then (
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
         {$workmap:meta}
         
        <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:type schema:genre" content="GeoBrowser view of Manuscripts of {$worksid}"></meta>
            <meta  xmlns="http://www.w3.org/1999/xhtml" property="og:site_name" content="Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea"></meta>
    <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:language schema:inLanguage" content="en"></meta>
    <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:rights" content="Copyright &#169; Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik.  Sharing and remixing permitted under terms of the Creative Commons Attribution Share alike Non Commercial 4.0 License (cc-by-nc-sa)."></meta>
    <meta   xmlns="http://www.w3.org/1999/xhtml" property="dcterms:publisher schema:publisher" content="Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik"></meta>
<link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/intro.js/2.9.3/introjs.css"  />
<link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/jquery.slick/1.6.0/slick.css"  />
        <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/jquery.slick/1.6.0/slick-theme.css"  />
        
{apprest:scriptStyle()}

<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"/>
    </head>
    <body id="body">
       {nav:barNew()}
        {nav:modalsNew()}
        <div id="content" class="w3-container w3-padding-64 w3-margin">
        <div class="w3-container">
        
    
        
            <div class="w3-container">
   <div class="w3-container alert alert-info">You can download the KML file visualized below in the <a href="https://geobrowser.de.dariah.eu">Dariah-DE Geobrowser</a>.</div>
   <h3>Map and timeline of places attestations marked up in the text.</h3>
   <iframe style="width: 100%; height: 1200px;" id="geobrowserMap" src="https://geobrowser.de.dariah.eu/embed/index.html?{string-join($kmlparam, '&amp;')}"/>
   </div>
            
        </div>
        </div>
         {nav:footerNew()}
<script type="text/javascript" src="https://cdn.jsdelivr.net/jquery.slick/1.6.0/slick.min.js"  />

        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/intro.js/2.9.3/intro.js"  ></script>
        <script type="application/javascript" src="resources/js/introText.js"/>
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




(:get a placemark for each manuscript which contains a given work:)
declare 
%rest:GET
%rest:path("/BetMas/workmap/KML/{$work}")
%output:method("xml")
function workmap:kml($work as xs:string) {
$config:response200,
let $log := log:add-log-message('/workmap/'||$work||'/KML/', xmldb:get-current-user(), 'workmap')
let $thisworkmss := $config:collection-rootMS//t:title[contains(@ref , $work)]
let $part := $config:collection-rootW//t:div[@type ='textpart'][@corresp = $work]
let $containedin := for $container in $part
                                       let $anchor := string($container/@xml:id)
                                        let $root := string(root($container)/t:TEI/@xml:id)
                                        let $IdPlusAnchor := $root || '#' ||$anchor
                                       return  $config:collection-rootMS//t:title[contains(@ref , $IdPlusAnchor)]
 let $mss := ($thisworkmss, $containedin)
let $worktitle := titles:printTitleID($work)
return
             workmap:kmlfile($mss, $worktitle)
             
};

declare function workmap:kmlfile($mss, $worktitle as xs:string){
<kml>
       {for $ms in $mss 
       let $msID := string(root($ms)/t:TEI/@xml:id)
       let $msName := titles:printTitleMainID($msID)
let $repo := root($ms)//t:repository
let $id := string(root($ms)/t:TEI/@xml:id)
let $date := root($ms)//t:origDate
let $getcoor := coord:getCoords($repo/@ref)
let $reponame := titles:printTitleMainID($repo/@ref)
       return 
(:       if($pRec//t:coord) then:)
       <Placemark>
        <address>{$reponame}</address>
        <description>{$msName}, which contains {$worktitle}.</description>
        <name>{$config:appUrl || '/' || $msID}</name>
        <Point>
            <coordinates>{coord:invertCoord($getcoor)}</coordinates>
        </Point>
         {let $all := ($date/@when, $date/@notBefore, $date/@notAfter)
         return 
         
            <TimeSpan>
            <begin>{min($all)}</begin>
            <end>{max($all)}</end>
            </TimeSpan>}
        
    </Placemark>      

    }</kml>
};