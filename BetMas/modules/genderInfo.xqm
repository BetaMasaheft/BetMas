xquery version "3.1" encoding "UTF-8";
(:~
 : module with all the main functions which can be called by the API.
 : 
 : @author Pietro Liuzzo 
 :)
module namespace genderInfo = "https://www.betamasaheft.uni-hamburg.de/BetMas/genderInfo";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMas/nav" at "xmldb:exist:///db/apps/BetMas/modules/nav.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMas/apprest" at "xmldb:exist:///db/apps/BetMas/modules/apprest.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace fusekisparql = 'https://www.betamasaheft.uni-hamburg.de/BetMas/sparqlfuseki' at "xmldb:exist:///db/apps/BetMas/fuseki/fuseki.xqm";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMas/switch2"  at "xmldb:exist:///db/apps/BetMas/modules/switch2.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace console = "http://exist-db.org/xquery/console";
import module namespace http = "http://expath.org/ns/http-client";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace dcterms = "http://purl.org/dc/terms";
declare namespace saws = "http://purl.org/saws/ontology";
declare namespace cmd = "http://www.clarin.eu/cmd/";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace s = "http://www.w3.org/2005/xpath-functions";
declare namespace sr = "http://www.w3.org/2005/sparql-results#";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare variable $genderInfo:query := "SELECT DISTINCT ?ms ?temporal ?repo ?person ?gender ?role ?occupation ?birth ?death ?bondType ?related
WHERE {
?annotation a ?role ;
    oa:hasBody ?person ;
    oa:hasTarget ?ms .
?ms a bm:mss .
OPTIONAL {  ?ms   dcterms:temporal ?temporal .}
 ?ms crm:P55_has_current_location ?repo .
?person foaf:gender ?gender .
  OPTIONAL {
   ?person        crm:P4_has_time_span [a crm:E67_Birth ;crm:P79_beginning_is_qualified_by ?birth] ; 
       crm:P4_has_time_span [a crm:E69_Death ; crm:P79_beginning_is_qualified_by ?death] .
  }
  OPTIONAL { ?person snap:occupation ?occupation}
  OPTIONAL {
    ?person snap:hasBond ?bond .
    ?bond a ?bondType ;
          snap:bond-with ?related .
  }
  FILTER STRSTARTS(STR(?role), 'https://betamasaheft.eu/')
}";

declare variable $genderInfo:sparqlquery := genderInfo:runquery() ;

declare function genderInfo:runquery() {
    let $query := $config:sparqlPrefixes ||$genderInfo:query
    return
        fusekisparql:query('betamasaheft', $query)
};

declare function genderInfo:filter($res, $gen){
for $r in $res//sr:binding[@name='gender'][sr:literal=$gen]
                                      let $p := $r/preceding-sibling::sr:binding[@name='person']
                                      group by $person := $p
                                      return $person
};

declare function genderInfo:timeline($sparql){
for $res in $sparql//sr:result[sr:binding[@name='birth']]
let $person := $res//sr:binding[@name='person']/sr:uri/text() 
            group by $p := $person
            let $id := substring-after($p,'https://betamasaheft.eu/')
            let $name := titles:printTitleMainID($id)
            let $birth := $res[1]/sr:binding[@name='birth']/sr:literal/text()
            let $death := $res[1]/sr:binding[@name='birth']/sr:literal/text()
            return
            '["'||$name||'", new Date('||replace($birth, '-', ', ') ||'), new Date('||replace($death, '-', ', ')||')]'
   
};
declare function genderInfo:TempBarChartData($sparql){
          for $res in $sparql//sr:result
            let $temp := $res//sr:binding[@name='temporal']/sr:uri/text() 
            group by $r := $temp
            let $rname := 
                     if (contains($r, 't5z3')) then '-0999–0000 (South-Arabian Pre-Aksumite and Proto-Aksumite)'
            else if (contains($r, 'tdn7')) then '0001–0300 (Early Aksumite)'
            else if (contains($r, '4qvv')) then '0300–0700 (Aksumite)'
            else if (contains($r, 'rjvk')) then '1200–1433 (Postaksumite I)'
            else if (contains($r, 'vm7f')) then '1434–1632 (Postaksumite II)'
            else if (contains($r, 'dh3k')) then '1632–1769 (Gondarine)'
            else if (contains($r, 'vtwm')) then '1769–1855 (Zamana Masāfǝnt)'
            else if (contains($r, 'fc3r')) then '1855–1974 (Modern Period)'
            else 'Not a valid PeriodO URI.'
                  let $countF := genderInfo:filter($res, 'female')
             let $countM := genderInfo:filter($res, 'male')
             order by $rname
            return 
            "['"||$rname||"',"|| count($countF)||','|| count($countM)||']'
};

declare function genderInfo:GenBarChartData($sparql){

            for $res in $sparql//sr:result
            let $role := $res//sr:binding[@name='role'] 
            group by $r := $role
            let $countF := genderInfo:filter($res, 'female')
             let $countM := genderInfo:filter($res, 'male')
            return 
            "['"||substring-after(replace($r, '\s', ''), 'https://betamasaheft.eu/')||"',"|| count($countF)||','|| count($countM)||']'
    
};
 
declare
%rest:GET
%rest:path("BetMas/gender/rels")
%output:method("json")
function genderInfo:relNodes(){
let $nodes :=
for $n in $genderInfo:sparqlquery[2]//sr:uri[starts-with(.,'https://betamasaheft.eu/')]
let $id := substring-after($n,'https://betamasaheft.eu/')
group by $i := $id
let $title := titles:printTitleMainID($i)
let $type := switch2:switchPrefix($i)
return
    map {
        "id" : ('https://betamasaheft.eu/'||$i), 
        "label" :  $title,
        "group" : $type
        }
let $edges := 
for $n in $genderInfo:sparqlquery//sr:result
return
(   
(:manuscript - repo:)
map {'from': $n//sr:binding[@name='ms']/sr:uri/text(), 
      'to': $n//sr:binding[@name='repo']/sr:uri/text(), 
      'label': 'repository',   'value':  1, 
      'font':  map {'align':  'top'}},
(:      manuscript - person (label = role) :)
map {'from': $n//sr:binding[@name='person']/sr:uri/text(), 
      'to': $n//sr:binding[@name='ms']/sr:uri/text(), 
      'label': substring-after($n//sr:binding[@name='role']/sr:uri/text(), 'https://betamasaheft.eu/'),   'value':  1, 
      'font':  map {'align':  'top'}},
(: persons - person (label = snap ) :)
if($n//sr:binding[@name='related']/sr:uri/text()) then 
map {'from': $n//sr:binding[@name='person']/sr:uri/text(), 
      'to': $n//sr:binding[@name='related']/sr:uri/text(), 
      'label': substring-after($n//sr:binding[@name='bondType']/sr:uri/text(),'http://data.snapdrgn.net/ontology/snap#'), 
        'value':  1, 
        'font':  map {'align':  'top'}}
        else ()
      )
     
return
(:returns the title and id of the entities referring to this entity or entity referring to those pointing to the entity:)
  ( map {'nodes' :   $nodes,
 'edges' :   $edges,
     'cN' :  count($nodes),
     'cE' :  count($edges)
 })
};

 
declare
%rest:GET
%rest:path("/BetMas/gender")
%output:method("html5")
function genderInfo:landingpage() {
  let $sparql:=  $genderInfo:sparqlquery[2]
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
        <html
            xmlns="http://www.w3.org/1999/xhtml">
            <head>
                <title
                    property="dcterms:title og:title schema:name">Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</title>
                <link
                    rel="shortcut icon"
                    href="resources/images/favicon.ico"/>
                <meta
                    name="viewport"
                    content="width=device-width, initial-scale=1.0"/>
                <meta
                    xmlns="http://www.w3.org/1999/xhtml"
                    property="og:site_name"
                    content="Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea"></meta>
                <meta
                    xmlns="http://www.w3.org/1999/xhtml"
                    property="dcterms:language schema:inLanguage"
                    content="en"></meta>
                <meta
                    xmlns="http://www.w3.org/1999/xhtml"
                    property="dcterms:rights"
                    content="Copyright &#169; Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik.  Sharing and remixing permitted under terms of the Creative Commons Attribution Share alike Non Commercial 4.0 License (cc-by-nc-sa)."></meta>
                <meta
                    xmlns="http://www.w3.org/1999/xhtml"
                    property="dcterms:publisher schema:publisher"
                    content="Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik"></meta>
                {apprest:scriptStyle()}
                <script
                    type="text/javascript"
                    src="https://www.gstatic.com/charts/loader.js"/>
            
            </head>
            
            <body
                id="body">
                {nav:barNew()}
                {nav:modalsNew()}
                <div
                    id="content"
                    class="w3-container w3-margin w3-padding-64">
                    <div
                        class="w3-container">
                        <h1>Gender and Manuscripts</h1>
                        <p>The visualizations linked from this page 
                            represent the results of a query to the SPARQL endpoint for <b>persons who we
                            know to have a role in
                            the manuscript production</b> 
                            and collects information from the manuscript where this
                            is encoded, the person, the institution where the manuscript is kept. 
                            Here you can find the <a target="_blank" href="/gender/data">raw 
                            response</a> or see it as 
                            a <a target="_blank" href="/gender/table">formatted table</a>.
                            Some <a target="_blank" href="/gender/page">breakdowns</a> and <a target="_blank" href="/gender/graph">graphs</a> are produced on the basis of this data.
                            This is the SPARQL query producing these results:
                            <code>{normalize-space($genderInfo:query)}</code>
                            </p>
                            <p>You can copy, edit it, paste it and use it from any 
                            application supporting
                            import from a SPARQL Endpoint, for example Palladio (endpoint is https://betamasaheft.eu/api/SPARQL/json), or in <a target="_blank" href="/sparql">our SPARQL Endpoint</a>.</p>
                        <p>At the moment the data contains some information 
                             about {count(distinct-values($sparql//sr:binding[@name="person"]))}, 
                             {count(genderInfo:filter($sparql, 'female'))} women 
                             and {count(genderInfo:filter($sparql, 'male'))} men. </p>
                             </div>
                             </div> {nav:footerNew()}
                <script
                    type="text/javascript"
                    src="resources/js/w3.js"/>
                <script
                    type="text/javascript"
                    src="resources/js/titles.js"/>
                <script
                    type="text/javascript"
                    src="resources/js/tablesorter.js"/>
            </body>
        </html>)
};

declare
%rest:GET
%rest:path("/BetMas/gender/data")
function genderInfo:data() {
    $genderInfo:sparqlquery[2]
};
    
declare
%rest:GET
%rest:path("/BetMas/gender/table")
%output:method("html5")
function genderInfo:table() {
    let $sparql := $genderInfo:sparqlquery[2]
   return 
        (<rest:response>
            <http:response
                status="200">
                <http:header
                    name="Content-Type"
                    value="text/html; charset=utf-8"/>
            </http:response>
        </rest:response>,
        <html
            xmlns="http://www.w3.org/1999/xhtml">
            <head>
                <title
                    property="dcterms:title og:title schema:name">Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</title>
                <link
                    rel="shortcut icon"
                    href="resources/images/favicon.ico"/>
                <meta
                    name="viewport"
                    content="width=device-width, initial-scale=1.0"/>
                <meta
                    xmlns="http://www.w3.org/1999/xhtml"
                    property="og:site_name"
                    content="Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea"></meta>
                <meta
                    xmlns="http://www.w3.org/1999/xhtml"
                    property="dcterms:language schema:inLanguage"
                    content="en"></meta>
                <meta
                    xmlns="http://www.w3.org/1999/xhtml"
                    property="dcterms:rights"
                    content="Copyright &#169; Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik.  Sharing and remixing permitted under terms of the Creative Commons Attribution Share alike Non Commercial 4.0 License (cc-by-nc-sa)."></meta>
                <meta
                    xmlns="http://www.w3.org/1999/xhtml"
                    property="dcterms:publisher schema:publisher"
                    content="Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik"></meta>
                {apprest:scriptStyle()}
                <script
                    type="text/javascript"
                    src="https://www.gstatic.com/charts/loader.js"/>
            
            </head>
            <body
                id="body">
                {nav:barNew()}
                {nav:modalsNew()}
                <div
                    id="content"
                    class="w3-container w3-margin w3-padding-64">
                    <div
                        class="w3-container">{
   
   transform:transform($sparql,
    'xmldb:exist:///db/apps/BetMas/rdfxslt/sparqltable.xsl', ())    }
    </div></div>
      {nav:footerNew()}
                <script
                    type="text/javascript"
                    src="resources/js/w3.js"/>
                <script
                    type="text/javascript"
                    src="resources/js/titles.js"/>
                <script
                    type="text/javascript"
                    src="resources/js/tablesorter.js"/>
            </body>
        </html>)
    };
    
declare
%rest:GET
%rest:path("/BetMas/gender/page")
%output:method("html5")
function genderInfo:page() {
    let $sparql := $genderInfo:sparqlquery[2]
    
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
        <html
            xmlns="http://www.w3.org/1999/xhtml">
            <head>
                <title
                    property="dcterms:title og:title schema:name">Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</title>
                <link
                    rel="shortcut icon"
                    href="resources/images/favicon.ico"/>
                <meta
                    name="viewport"
                    content="width=device-width, initial-scale=1.0"/>
                <meta
                    xmlns="http://www.w3.org/1999/xhtml"
                    property="og:site_name"
                    content="Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea"></meta>
                <meta
                    xmlns="http://www.w3.org/1999/xhtml"
                    property="dcterms:language schema:inLanguage"
                    content="en"></meta>
                <meta
                    xmlns="http://www.w3.org/1999/xhtml"
                    property="dcterms:rights"
                    content="Copyright &#169; Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik.  Sharing and remixing permitted under terms of the Creative Commons Attribution Share alike Non Commercial 4.0 License (cc-by-nc-sa)."></meta>
                <meta
                    xmlns="http://www.w3.org/1999/xhtml"
                    property="dcterms:publisher schema:publisher"
                    content="Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik"></meta>
                {apprest:scriptStyle()}

                <script
                    type="text/javascript"
                    src="https://www.gstatic.com/charts/loader.js"/>
            </head>
            
            <body
                id="body">
                {nav:barNew()}
                {nav:modalsNew()}
                <div
                    id="content"
                    class="w3-container w3-margin w3-padding-64">
                    <div
                        class="w3-container">
                        <p>Back to <a href="/gender">Gender and Manuscripts.</a></p>
                        <div
                            class="w3-container">
                            <!-- 
                            https://observablehq.com/@d3/sunburst
                            break down female/male (pie of total brek down by period) -->
                        </div>
                        <div
                            class="w3-container">
                         <!--   https://observablehq.com/@d3/sortable-bar-chart
                             https://observablehq.com/@d3/grouped-bar-chart
                             https://observablehq.com/@d3/diverging-stacked-bar-chart
                             bar chart by role in ms production per period: female/male columns compared -->
                             <div id="barchart_div"/>
                             <script>
                             {"google.charts.load('current', {packages: ['corechart', 'bar']});
google.charts.setOnLoadCallback(drawMultSeries);

function drawMultSeries() {
      var data = new google.visualization.DataTable();
      data.addColumn('string', 'Roles');
      data.addColumn('number', 'Female');
      data.addColumn('number', 'Male');

      data.addRows(["||string-join(genderInfo:GenBarChartData($sparql),',')||"]);

      var options = {
        title: 'Role distribution by Gender',
          isStacked: 'percent',
          height: 300,
          legend: {position: 'top', maxLines: 3},
        hAxis: {
          title: 'Roles',
        },
        vAxis: {
          title: 'Total known instances'
        }
      };

      var chart = new google.visualization.ColumnChart(
        document.getElementById('barchart_div'));

      chart.draw(data, options);
    }"
    
}    </script>
<div id="datechart_div"/>
<script>
                             {"google.charts.load('current', {packages: ['corechart', 'bar']});
google.charts.setOnLoadCallback(drawMultSeries);

function drawMultSeries() {
      var data = new google.visualization.DataTable();
      data.addColumn('string', 'Periods');
      data.addColumn('number', 'Female');
      data.addColumn('number', 'Male');

      data.addRows(["||string-join(genderInfo:TempBarChartData($sparql),',')||"]);

      var options = {
        title: 'Attested roles over periods',
          isStacked: 'percent',
          height: 300,
          legend: {position: 'top', maxLines: 3},
        hAxis: {
          title: 'Roles',
        },
        vAxis: {
          title: 'Total known instances'
        }
      };

      var chart = new google.visualization.ColumnChart(
        document.getElementById('datechart_div'));

      chart.draw(data, options);
    }"
    
}    </script>
                        </div>
                        
                        
                        <div
                            class="w3-container">
                            <!-- timeline of persons involved-->
                            <div id="timeline" style='height:400px;'></div>
                            <script type="text/javascript">{"
      google.charts.load('current', {'packages':['timeline']});
      google.charts.setOnLoadCallback(drawChart);
      function drawChart() {
        var container = document.getElementById('timeline');
        var chart = new google.visualization.Timeline(container);
        var dataTable = new google.visualization.DataTable();

        dataTable.addColumn({ type: 'string', id: 'person' });
        dataTable.addColumn({ type: 'date', id: 'birth' });
        dataTable.addColumn({ type: 'date', id: 'death' });
        dataTable.addRows(["||string-join(genderInfo:timeline($sparql), ',')||"]);

        chart.draw(dataTable);
      }"}
    </script>
                        </div>
                        
                    </div>
                </div>
                {nav:footerNew()}
                <script
                    type="text/javascript"
                    src="resources/js/w3.js"/>
                <script
                    type="text/javascript"
                    src="resources/js/titles.js"/>
                <script
                    type="text/javascript"
                    src="resources/js/tablesorter.js"/>
            </body>
        </html>
        )
};

declare
%rest:GET
%rest:path("/BetMas/gender/graph")
%output:method("html5")
function genderInfo:graph() {
    let $sparql := $genderInfo:sparqlquery[2]
    
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
        <html
            xmlns="http://www.w3.org/1999/xhtml">
            <head>
                <title
                    property="dcterms:title og:title schema:name">Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</title>
                <link
                    rel="shortcut icon"
                    href="resources/images/favicon.ico"/>
                <meta
                    name="viewport"
                    content="width=device-width, initial-scale=1.0"/>
                <meta
                    xmlns="http://www.w3.org/1999/xhtml"
                    property="og:site_name"
                    content="Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea"></meta>
                <meta
                    xmlns="http://www.w3.org/1999/xhtml"
                    property="dcterms:language schema:inLanguage"
                    content="en"></meta>
                <meta
                    xmlns="http://www.w3.org/1999/xhtml"
                    property="dcterms:rights"
                    content="Copyright &#169; Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik.  Sharing and remixing permitted under terms of the Creative Commons Attribution Share alike Non Commercial 4.0 License (cc-by-nc-sa)."></meta>
                <meta
                    xmlns="http://www.w3.org/1999/xhtml"
                    property="dcterms:publisher schema:publisher"
                    content="Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik"></meta>
                {apprest:scriptStyle()}
                <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/vis/4.12.0/vis.min.js"  />
            </head>
            
            <body
                id="body">
                {nav:barNew()}
                {nav:modalsNew()}
                <div
                    id="content"
                    class="w3-container w3-margin w3-padding-64">
                    <div
                        class="w3-container">
                        <p>Back to <a href="/gender">Gender and Manuscripts.</a></p>
                        
                        <div
                            class="w3-container">
                          <!--  https://observablehq.com/@d3/mobile-patent-suits
                          https://observablehq.com/@d3/chord-diagram
                             force graph manuscript / persons + person / person + manuscript / repo-->
                             <div id="BetMasRel" class="w3-padding" >


                <div class="input-group container">
                    <button id="clusterOutliers" class="w3-button w3-gray">Cluster outliers</button>
                    <button id="clusterByHubsize" class="w3-button w3-gray">Cluster by hubsize</button>
                </div>
               <div id="BetMasRelView" class="w3-container"/>
                <script type="text/javascript"src="resources/js/visgraphspecgender.js"/>
                </div>
                        </div>
                        
                    </div>
                </div>
                {nav:footerNew()}
                <script
                    type="text/javascript"
                    src="resources/js/w3.js"/>
                <script
                    type="text/javascript"
                    src="resources/js/titles.js"/>
                <script
                    type="text/javascript"
                    src="resources/js/tablesorter.js"/>
            </body>
        </html>
        )
};