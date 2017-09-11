xquery version "3.1" encoding "UTF-8";

module namespace homepage = "https://www.betamasaheft.uni-hamburg.de/BetMas/home";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace app = "https://www.betamasaheft.uni-hamburg.de/BetMas/app" at "app.xqm";
import module namespace item = "https://www.betamasaheft.uni-hamburg.de/BetMas/item" at "item.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMas/nav" at "nav.xqm";
import module namespace BetMasMap = "https://www.betamasaheft.uni-hamburg.de/BetMas/map" at "map.xqm";
import module namespace error = "https://www.betamasaheft.uni-hamburg.de/BetMas/error" at "error.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMas/apprest" at "apprest.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace console = "http://exist-db.org/xquery/console";(:
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";:)
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

declare 
%rest:GET
%rest:path("/BetMas/home")
%output:method("html5")
function homepage:index() {
  
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
        <link rel="shortcut icon" href="resources/images/favicon.ico"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
       <meta  xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>
    {for $genauthor in $config:repo-descriptor/repo:author
    return
        <meta xmlns="http://www.w3.org/1999/xhtml" name="creator" content="{$genauthor/text()}"></meta>}

        {apprest:scriptStyle()}
        
        {apprest:ItemScriptStyle()}
    </head>
    <body id="body">
        {nav:bar()}
        {nav:modals()}
        {nav:searchhelp()}
 
        <div id="content" class="container-fluid col-md-12">
        <div class="col-md-6">
        <div class="page-header">
            <h1>{$config:app-title}</h1>
        </div>
    </div>
    <div class="col-md-6">
        <div class="alert alert-success">
            <p>
                The project Beta
                maṣāḥǝft: Manuscripts of Ethiopia and Eritrea (Schriftkultur des christlichen
                Äthiopiens: eine multimediale Forschungsumgebung) is a long-term project
                funded within the framework of the Academies' Programme (coordinated by the Union of
                the German Academies of Sciences and Humanities) under survey of the Akademie der
                Wissenschaften in Hamburg. The funding will be provided for 25 years, from
                2016–2040. The project is hosted by the Hiob Ludolf Centre for Ethiopian Studies at
                the University of Hamburg. It aims at creating a virtual research environment that
                shall manage complex data related to predominantly Christian manuscript tradition of
                the Ethiopian and Eritrean Highlands.</p>
        </div>
    </div>
    <div class="row-fluid">
        <div class=" col-md-6">
            <ul class="nav nav-tabs">
                <li class="active">
                    <a data-toggle="tab" href="#map">Places with coordinates in our gazetteer</a>
           </li>
                <li>
                    <a data-toggle="tab" href="#origPlaces">Places of provenance of manuscripts</a>
                </li>
            </ul> 
            <div class="tab-content">
                <div id="map" class="tab-pane fade in active"/>
           <script type="text/javascript">
                {BetMasMap:RestMAP()}
            </script>
            
                <div id="origPlaces" class="tab-pane fade in">
                <iframe style="width: 100%; height: 800px;" id="geobrowserMap" src="http://geobrowser.de.dariah.eu/embed/index.html?kml1={$config:appUrl}/api/KML/manuscripts/origPlaces"/>
            </div>
            </div>
                
            <div class="embed-responsive embed-responsive-16by9">
                <iframe class="embed-responsive-item" src="https://www.youtube.com/embed/bI950izCu2E" allowfullscreen="allowfullscreen"/>
            </div>
        </div>
        <div class="col-md-6">
            <div class="alert alert-info fade in" id="count">
                <a href="#" class="close" data-dismiss="alert" aria-label="close">close</a>
                <div data-template="app:count"/>
            </div>
            {(:app:academics():)' '}
                <div class="alert alert-default fade in" id="latest">
                <a href="#" class="close" data-dismiss="alert" aria-label="close">close</a>
         {(:app:latest():)' '}
            </div>
        </div>
    </div>
    <div class="row-fluid"><!-- start feedwind code -->
        <script type="text/javascript" src="https://feed.mikle.com/js/fw-loader.js" data-fw-param="9855/"/> <!-- end feedwind code -->
    </div>
    <script>$( ".fa-hand-o-left" ).remove()</script>

        </div>
        {nav:footer()}
       
    
    </body>
</html>
       
};