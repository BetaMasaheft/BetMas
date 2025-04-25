xquery version "3.1" encoding "UTF-8";
(:~
 : template like RESTXQ module to generate the comparison page
 : 
 : @author Pietro Liuzzo 
 :)

module namespace workmap = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/workmap";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace app = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/app" at "xmldb:exist:///db/apps/BetMasWeb/modules/app.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/nav" at "xmldb:exist:///db/apps/BetMasWeb/modules/nav.xqm";
import module namespace scriptlinks = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/scriptlinks" at "xmldb:exist:///db/apps/BetMasWeb/modules/scriptlinks.xqm";
import module namespace error = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/error" at "xmldb:exist:///db/apps/BetMasWeb/modules/error.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace coord = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/coord" at "xmldb:exist:///db/apps/BetMasWeb/modules/coordinates.xqm";
import module namespace exptit="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace ann = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ann" at "xmldb:exist:///db/apps/BetMasWeb/modules/annotations.xqm";

declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace dcterms = "http://purl.org/dc/terms";
declare namespace saws = "http://purl.org/saws/ontology";
declare namespace cmd = "http://www.clarin.eu/cmd/";
declare namespace test="http://exist-db.org/xquery/xqsuite";

(: For REST annotations :)
declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";

declare variable $workmap:collection-rootW := collection($config:data-rootW);
declare variable $workmap:collection-rootMS := collection($config:data-rootMS);
declare variable $workmap:meta := <meta  xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $genauthor in $config:repo-descriptor/repo:author
    return
        <meta xmlns="http://www.w3.org/1999/xhtml" name="creator" content="{$genauthor/text()}"></meta>
        ;



declare 
%rest:GET
%rest:POST
%rest:path("/BetMasWeb/workmap")
%rest:query-param("worksid", "{$worksid}", "")
%rest:query-param("type", "{$type}", "repo")
%output:method("html5")
function workmap:workmap(
$worksid as xs:string*, $type as xs:string*) {
let $fullurl := ('?worksid=' || $worksid)
let $log := log:add-log-message($fullurl, sm:id()//sm:real/sm:username/string() , 'worksmap')
let $w :=  if(contains($worksid, ',')) then for $work in tokenize($worksid, ',') return $workmap:collection-rootW/id($work) else $workmap:collection-rootW/id($worksid)  
let $baseuris := for $bu in $w return base-uri($bu)
let $Cmap := map {'type': 'item', 'name' : $worksid, 'path' : string-join($baseuris)}
let $kmlparam := for $work at $p in $w/@xml:id return  'kml'||$p||'=https://betamasaheft.eu/workmap/KML/'||string($work)||'?type='||$type
let $worktitles := for $work in $w/@xml:id return exptit:printTitleID($work)
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
    <script async="async" src="https://www.googletagmanager.com/gtag/js?id=UA-106148968-1"></script>
        <script type="text/javascript" src="resources/js/analytics.js"></script>
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
        
{scriptlinks:scriptStyle()}

<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"/>
    </head>
    <body id="body">
       {nav:barNew()}
        {nav:modalsNew()}
        <div id="content" class="w3-container w3-padding-64 w3-margin">
        <div class="w3-container">
        
    
        <form action="" class="w3-container" 
        data-hint="enter here the id of the work you would like to show on the map.">
        <select class="w3-select w3-border" name="type">
        <option value="repo">Repository</option>
        <option value="orig">Place of origin</option>
        </select>
        <input 
        class="w3-input w3-border" list="gotohits" id="GoTo" 
        name="worksid" data-value="works">{if(count($worksid) gt 0) then attribute value {$worksid} else attribute placeholder {"choose work to produce map of manuscripts"} }</input>
               <datalist id="gotohits">
                    
                </datalist>
          <div class="w3-bar"><button type="submit" class="w3-bar-item w3-button w3-red"> Show on map
                </button><a class="w3-bar-item w3-button w3-gray" href="javascript:void(0);" 
        onclick="javascript:introJs().addHints();">show hints</a></div>
    </form>
            <div class="w3-container">
   <div class="w3-container alert alert-info">You can download the KML file visualized below in the <a href="https://geobrowser.de.dariah.eu">Dariah-DE Geobrowser</a>.</div>
   <h3>Map of the manuscripts {if($type= 'repo') then ' at their current location' else ' at their place of origin'}</h3>
   <p>Map of the manuscripts of {string-join($worktitles, '; ')} {if($type= 'repo') then ' at their current location' else ' at their place of origin'}.</p>
   <p>For each textual unit a different color of dots is given (i.e. a different KML file is loaded). 
   For each manuscript containing the selected textual units the point is placed at the current repository or at the place of origin according
   to the selection. The default is the current repository. 
   If place of origin is selected and for the manuscript this information is not available (e.g. in cases where 
   this corresponds in fact to the current repository), the point will be made on the repository which is always available.
   The dates given for each manuscript correspond to the most inclusive range possible from the origin dates given in the manuscript.
   If a manuscript has a part from exactly 1550 and one dated 1789 to 1848, then the time span will be 1550 - 1848.</p>
   <iframe style="width: 100%; height: 1200px;" id="geobrowserMap" src="https://geobrowser.de.dariah.eu/embed/index.html?{string-join($kmlparam, '&amp;')}"/>
<div class="w3-panel w3-card-2 w3-red">You do not find all the information you would like to 
    have?  <a href="https://betamasaheft.eu/Guidelines/?id=howto">Help improve the data and contribute to the project editing the files!</a></div>
  
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
%rest:path("/BetMasWeb/workmap/KML/{$work}")
%rest:query-param("type", "{$type}", "repo")
%output:method("xml")
function workmap:kml($work as xs:string, $type as xs:string*) {
$config:response200,
let $log := log:add-log-message('/workmap/'||$work||'/KML/', sm:id()//sm:real/sm:username/string(), 'workmap')
let $thisworkmss := $workmap:collection-rootMS//t:title[@ref = $work]
let $part := $workmap:collection-rootW//t:div[@type ='textpart'][@corresp = $work]
let $containedin := for $container in $part
                                       let $anchor := string($container/@xml:id)
                                        let $root := string(root($container)/t:TEI/@xml:id)
                                        let $IdPlusAnchor := $root || '#' ||$anchor
                                       return  $workmap:collection-rootMS//t:title[@ref = $IdPlusAnchor]
 let $mss := ($thisworkmss, $containedin)
let $worktitle := exptit:printTitle($work)
return
             workmap:kmlfile($mss, $worktitle, $type)
             
};

declare function workmap:kmlfile($mss, $worktitle as xs:string, $type as xs:string*){
<kml>
       {for $ms in $mss 
       let $msID := string(root($ms)/t:TEI/@xml:id)
       let $msName := exptit:printTitle($msID)
let $place := if($type='repo') then root($ms)//t:repository[1] else ( if(root($ms)//t:origPlace[t:placeName]) then root($ms)//t:origPlace[1]/t:placeName[1] else  root($ms)//t:repository[1])
let $id := string(root($ms)/t:TEI/@xml:id)
let $date := root($ms)//t:origDate
let $when := if (contains($date/@when, '-')) then substring-before($date/@when, '-') else $date/@when
let $getcoor := coord:getCoords($place[1]/@ref)
let $reponame := exptit:printTitle($place[1]/@ref)
       return 
(:       if($pRec//t:coord) then:)
       <Placemark>
        <address>{$reponame} ({if(not($type='repo') and root($ms)//t:origPlace[t:placeName]) then 'place of origin' else 'repository'})</address>
        <description>{$msName}, which contains {$worktitle}.</description>
        <name>{$config:appUrl || '/' || $msID}</name>
        <Point>
            <coordinates>{coord:invertCoord($getcoor)}</coordinates>
        </Point>
         {let $all := ($when, $date/@notBefore, $date/@notAfter)
         return 
         
            <TimeSpan>
            <begin>{min($all)}</begin>
            <end>{max($all)}</end>
            </TimeSpan>}
        
    </Placemark>      

    }</kml>
};