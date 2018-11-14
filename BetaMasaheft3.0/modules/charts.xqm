xquery version "3.1" encoding "UTF-8";
(:~
 : module used to produce charts from Google charts
 :
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)
 
module namespace charts = "https://www.betamasaheft.uni-hamburg.de/BetMas/charts";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace sparql="http://exist-db.org/xquery/sparql" at "java:org.exist.xquery.modules.rdf.SparqlModule";
import module namespace titles = "https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "titles.xqm";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace sr = "http://www.w3.org/2005/sparql-results#";
declare namespace s = "http://www.w3.org/2005/xpath-functions";

declare function charts:mssSankey($itemid){
  let $query := ($config:sparqlPrefixes || "
  SELECT DISTINCT ?from ?to ?weight
  WHERE {
          BIND('"|| $itemid || "' as ?id)
          {
              ?from SdC:constituteUnit ?to .
              BIND(1 as ?weight)
            }
        UNION
        {
              ?from SdC:undergoesTransformation ?tr .
              ?tr SdC:resultsIn ?to .
              BIND(2 as ?weight)
            }
        UNION
        {
              ?from SdC:undergoesTransformation ?tr .
              ?tr SdC:produces ?to .
              BIND(2 as ?weight)
            }
        UNION
        {
              ?from skos:exactMatch ?to .
              ?to a SdC:UniCirc .
              BIND(4 as ?weight)
            }
  BIND(STR(?from) as ?strform)
  BIND(STR(?to) as ?strto)
  FILTER(contains(?strform, ?id))
  FILTER(contains(?strto, ?id))
   }"
  )

  let $sparqlresults := sparql:query($query)
  let $results := for $result in $sparqlresults//sr:result
                 let $from := substring-after($result//sr:binding[1]/sr:uri, 'http://betamasaheft.eu/')
                 let $to := substring-after($result//sr:binding[2]/sr:uri, 'http://betamasaheft.eu/')
                 let $w := $result//sr:binding[3]/sr:literal
                 return '["' ||  $from || '", "' || $to || '", ' ||  $w || ']'

  let $table := '[' ||string-join($results, ', ') || ']'
  return
  (<script src="//cdn.rawgit.com/newrelic-forks/d3-plugins-sankey/master/sankey.js"></script>,
    <script type="text/javascript">
  {"
      google.charts.load('current', {'packages':['sankey']});
      google.charts.setOnLoadCallback(drawChart);

      function drawChart() {
        var data = new google.visualization.DataTable();
        data.addColumn('string', 'From');
        data.addColumn('string', 'To');
        data.addColumn('number', 'Weight');
        data.addRows(" ||
      $table
     || ");
     
var options = {
      sankey: {
        node: { label: {
                         bold: true } } },
    };

       var chart = new google.visualization.Sankey(document.getElementById('sankey_basic'));
       chart.draw(data, options);
     }
     "

    }

  </script>,
  <div id="sankey_basic" style="width: 100%; height: 300px;"/>
  )
};


declare function charts:pieAttestations($itemid, $name){
  let $path:= 'collection($config:data-root)//t:' || $name || '[@ref=$itemid][text()]'
  let $attestations := util:eval($path)
  let $forms := for $att in $attestations
                 let $groupkey := normalize-space(string-join($att/text(), ' '))
                  group by $gk := $groupkey
                return
                '["' ||  $gk || '", ' ||  count($att) || ']'

  let $table := '[["form","total"],' ||string-join($forms, ', ') || ']'

      return
      (<script type="text/javascript">
      {'google.charts.load("current", {packages:["corechart"]});
        google.charts.setOnLoadCallback(drawChart);
        function drawChart() {
          var data = google.visualization.arrayToDataTable(' ||
          $table
         || ");

          var options = {
            title: 'percentual breakdown of " || count($attestations) ||" attested forms',
            is3D: true,
          };

          var chart = new google.visualization.PieChart(document.getElementById('piechart_3d'));
          chart.draw(data, options);
        }"

        }

      </script>,
      <div id="piechart_3d" style="width: 900px; height: 500px;"/>
      )
};

declare function charts:dateFilter($from, $to, $hits){
  $hits[descendant::t:origDate[(if (contains(@notBefore, '-'))
                                                                              then (substring-before(@notBefore, '-'))
                                                                              else @notBefore)[. !=''][number(.) >= $from][number(.)  <= $to]
                                                                              or
                                                                             (if (contains(@notAfter, '-'))
                                                                              then (substring-before(@notAfter, '-'))
                                                                              else @notAfter)[. !=''][number(.) >= $from][number(.)  <= $to]]]
};

declare function charts:chart($hits){
    let $mssAks := charts:dateFilter(0300, 0700, $hits)
    let $mssPaks1 := charts:dateFilter(1200, 1433, $hits)  
    let $mssPaks2 := charts:dateFilter(1434, 1632, $hits)
    let $mssGon := charts:dateFilter(1632, 1769, $hits)
    let $mssZaMe := charts:dateFilter(1769, 1855, $hits)
    let $mssMoPe := charts:dateFilter(1855, 1974, $hits)
    
  let $mss1-299 := charts:dateFilter(0001, 0299, $hits)
  let $mss300-599 := charts:dateFilter(0300, 0599, $hits)
  let $mss600-899 := charts:dateFilter(0600, 0899, $hits)
  let $mss900-1199 := charts:dateFilter(0900, 1199, $hits)
  let $mss1200-1499 := charts:dateFilter(1200, 1499, $hits)
  let $mss1500-1799 := charts:dateFilter(1500, 1799, $hits)
  let $mss1800-2099 := charts:dateFilter(1800, 2099, $hits)
  
  let $mssNotDated := $hits[not(descendant::t:origDate)]
  
  let $countAks := count($mssAks)
  let $countPaks1 := count($mssPaks1)
  let $countPaks2 := count($mssPaks2)
  let $countGon := count($mssGon)
  let $countZaMe := count($mssZaMe)
  let $countMoPe := count($mssMoPe)
  
  let $count1-299 := count($mss1-299)
  let $count300-599 := count($mss300-599)
  let $count600-899 := count($mss600-899)
  let $count900-1199 := count($mss900-1199)
  let $count1200-1499 := count($mss1200-1499)
  let $count1500-1799 := count($mss1500-1799)
  let $count1800-2099 := count($mss1800-2099)
  
  let $countNotDated := count($mssNotDated)

  let $countmswithSSta := count($hits[descendant::t:decoNote[@type='SewingStations']])
  let $spvalues := distinct-values($hits//t:decoNote[@type='SewingStations'])

  let $countmswithSPat := count($hits[descendant::t:term[starts-with(@key,'pattern')]])
  let $spatvalues := distinct-values($hits//t:term[starts-with(@key, 'pattern')]/@key)

  let $countmswithThreadMat := count($hits[descendant::t:term[ends-with(@key, 'Thread') or contains(@key, 'tannedSkin')]])
  let $TMvalues := distinct-values($hits//t:term[ends-with(@key, 'Thread') or contains(@key, 'tannedSkin')]/@key)


    let $countmswithbindingMat := count($hits[descendant::t:decoNote[parent::t:binding][t:material]])
    let $BMvalues := distinct-values($hits//t:decoNote[parent::t:binding]/t:material/@key)

    let $countmswithMainMat := count($hits[descendant::t:support[t:material]])
    let $MMvalues := distinct-values($hits//t:support/t:material/@key)


        let $countmsObjTyp := count($hits[descendant::t:objectDesc])
        let $OTvalues := distinct-values($hits//t:objectDesc/@form)

  let $numberQuiresIns := count($hits//t:collation[descendant::t:item])
  let $dimensions := $hits//t:extent[descendant::t:dimensions[@type='outer'][t:height][t:width][t:depth]]
  let $units := ($dimensions/t:dimensions[@type='outer']/@unit, $dimensions/t:dimensions[@type='outer']/t:*/@unit)
  let $unit := distinct-values($units)
  let $countDim := count($dimensions)
  let $layoutdimensions := $hits//t:layoutDesc/t:layout[descendant::t:dimensions[t:height][t:width]]
  let $countLayout := count($layoutdimensions)

  let $rulingpattern := $hits//t:ab[@type="ruling"][@subtype="pattern"]
  let $countRulPat := count($rulingpattern)
  
      return
 (

   if($numberQuiresIns ge 1) then (
 if($numberQuiresIns ge 1050 ) then (<div  class="col-md-6 alert alert-danger"><p>
    We think that a chart with data from {$numberQuiresIns} items would be impossible to read and not useful. Filter your search to limit the number of items, with less then 1000 we will print also the charts.
  </p></div>) else
let $dimensionOfQuiresINS := distinct-values($hits//t:collation//t:item/t:dim[@unit='leaf'])
let $percents := for $dim in $dimensionOfQuiresINS
                let $numberQuiresThisDim := count($hits//t:collation//t:item/t:dim[@unit='leaf'][.=$dim])
                order by $numberQuiresThisDim descending
                  return
                               '["' ||  $dim || ' leaves ", ' ||  $numberQuiresThisDim || ']'
let $collations := '[["Composition","Quantity"],' ||string-join($percents, ', ') || ']'

    return
    (<script type="text/javascript">
    {'google.charts.load("current", {packages:["corechart"]});
      google.charts.setOnLoadCallback(drawChart);
      function drawChart() {
        var data = google.visualization.arrayToDataTable(' ||
        $collations
       || ");

        var options = {
          title: 'Quires Distribution for the "||$numberQuiresIns||" codicological units in this selection which have a collation with quire descriptions',
          is3D: true,
        };

        var chart = new google.visualization.PieChart(document.getElementById('piechart_3d'));
        chart.draw(data, options);
      }"

      }

    </script>,
    <div id="piechart_3d" class="col-md-6"
     style="height: 500px;"/>
    )
    )
    else (<div  class="col-md-6 alert alert-warning" ><p>There are no collations for this selection of manuscripts.</p></div>),



if($countDim ge 1) then (
if($countDim ge 1050 ) then (<div  class="col-md-6 alert alert-danger"><p>
  We think that a chart with data from {$countDim} items would be impossible to read and not useful. Filter your search to limit the number of items, with less then 1000 we will print also the graphs.
</p></div>) else
if (count($unit) gt 1) then (<div  class="col-md-6 alert alert-warning"><p>Unfortunately we cannot put on a chart this data, because it is provided using different units of measure ({string-join($unit,', ')})</p></div>) else
    let $dims := for $d in $dimensions
    let $all := $d/t:dimensions[@type='outer']
                        let $SM := $d//ancestor::t:TEI//t:msIdentifier/t:idno/text()
                        let $title := titles:printTitle($d)
                        let $h := if($all/t:height/text()) then $all/t:height/text() else '0'
                        let $w := if($all/t:width/text()) then $all/t:width/text() else '0'
                        let $dep :=if($all/t:depth/text()) then $all/t:depth/text() else '0'
                                    return
                                    '["'||$SM||'",'||$w||','||$h||',"'||$title||'",'||$dep||']'

let $dimensionsTable := '[["shelf mark","widht","height","title","depth"],' ||string-join($dims, ', ') || ']'

let $taglie := for $d in $hits//t:extent[descendant::t:dimensions[@type='outer'][t:height][t:width][t:depth]]
               let $all := $d/t:dimensions[@type='outer']
               let $h := if($all/t:height/text()) then string-join($all/t:height/text(), ' ') else '0'
               let $w := if($all/t:width/text()) then string-join($all/t:width/text(), ' ') else '0'
               let $realtaglia := number($h) + number($w)

               let $grouppedtaglia := if($realtaglia lt 200) then '0-200'
                                                               else if(($realtaglia ge 200) and ($realtaglia le 249) ) then '200-249'
                                                                else if(($realtaglia ge 250) and ($realtaglia le 299) ) then '250-299'
                                                                else if(($realtaglia ge 300) and ($realtaglia le 349) ) then '300-349'
                                                                else if(($realtaglia ge 350) and ($realtaglia le 399) ) then '350-399'
                                                                else if(($realtaglia ge 400) and ($realtaglia le 449) ) then '400-449'
                                                                else if(($realtaglia ge 450) and ($realtaglia le 499) ) then '450-499'
                                                                else if(($realtaglia ge 500) and ($realtaglia le 549) ) then '500-549'
                                                                else if(($realtaglia ge 550) and ($realtaglia le 599) ) then '550-599'
                                                                else if(($realtaglia ge 600) and ($realtaglia le 649) ) then '600-649'
                                                                else if(($realtaglia ge 650) and ($realtaglia le 699) ) then '650-699'
                                                               else '700-2000'
                  group by $GT := $grouppedtaglia
                  order by $GT
                            let $from := number(substring-before($GT, '-'))
                            let $to := number(substring-after($GT, '-'))
                            let $percAks := if($countAks ge 1) then (charts:tagliasupport($mssAks, $countAks, $from, $to)) else 0
                            let $percPaks1 := if($countPaks1 ge 1) then (charts:tagliasupport($mssPaks1, $countPaks1, $from, $to)) else 0
                            let $percPaks2 := if($countPaks2 ge 1) then (charts:tagliasupport($mssPaks2, $countPaks2, $from, $to)) else 0
                            let $percGon := if($countGon ge 1) then (charts:tagliasupport($mssGon, $countGon, $from, $to)) else 0
                            let $percZaMe := if($countZaMe ge 1) then (charts:tagliasupport($mssZaMe, $countZaMe, $from, $to)) else 0
                            let $percMoPe := if($countMoPe ge 1) then (charts:tagliasupport($mssMoPe, $countMoPe, $from, $to)) else 0
                            
                            let $perc1-299 := if($count1-299 ge 1) then (charts:tagliasupport($mss1-299, $count1-299, $from, $to)) else 0
                            let $perc300-599 := if($count300-599 ge 1) then  (charts:tagliasupport($mss300-599, $count300-599, $from, $to)) else 0
                            let $perc600-899 :=   if($count600-899 ge 1) then  (charts:tagliasupport($mss600-899, $count600-899, $from, $to)) else 0
                            let $perc900-1199 := if($count900-1199 ge 1) then (charts:tagliasupport($mss900-1199, $count900-1199, $from, $to)) else 0
                            let $perc1200-1499 :=  if($count1200-1499 ge 1) then  (charts:tagliasupport($mss1200-1499, $count1200-1499, $from, $to)) else 0
                            let $perc1500-1799 := if($count1500-1799 ge 1) then (charts:tagliasupport($mss1500-1799, $count1500-1799, $from, $to)) else 0
                            let $perc1800-2099 :=  if($count1800-2099 ge 1) then (charts:tagliasupport($mss1800-2099, $count1800-2099, $from, $to)) else 0
                            let $percNotDated := if($countNotDated ge 1) then  (charts:tagliasupport($mssNotDated, $countNotDated, $from, $to)) else 0
                   return
                         '["'||$GT||'",'||
               $percAks||','||
               $percPaks1||','||
               $percPaks2||','||
               $percGon||','||
               $percZaMe||','||
               $percMoPe||','||
               $perc1-299||','||
               $perc300-599||','||
               $perc600-899||','||
               $perc900-1199||','||
               $perc1200-1499||','||
               $perc1500-1799||','||
               $perc1800-2099||','||
               $percNotDated
               ||']'
     let $taglieChart :=   '[["taglia","Aksumite","Post-aksumite I","Post-aksumite II","Gondarine","Zamana Masāfǝnt","Modern Period","I-III","IV-VI","VI-IX","X-XII","XIII-XV","XVI-XVIII","XIX-XXI","not dated"],' ||string-join($taglie, ', ') || ']'

    return
    (
    <script type="text/javascript">
      {'google.charts.load("current", {"packages":["corechart"]});
      google.charts.setOnLoadCallback(drawSeriesChart);

    function drawSeriesChart() {

      var data = google.visualization.arrayToDataTable(
      '||$dimensionsTable||'
      );

      var options = {
        title: "Ratio of dimensions of the ' ||$countDim||' codicological units which have all outer dimensions recorded (in ' ||$unit||') ",
        hAxis: {title: "width"},
        vAxis: {title: "height"},
        bubble: {textStyle: {fontSize: 11}}
      };

      var chart = new google.visualization.BubbleChart(document.getElementById("series_chart_div"));
      chart.draw(data, options);
    }
    '}
    </script>,
    <div id="series_chart_div"  class="col-md-6"
     style="height: 500px;"></div>,
    <script type="text/javascript">
    {
    "google.charts.load('current', {'packages':['line']});
      google.charts.setOnLoadCallback(drawChart);

      function drawChart() {
        var data = google.visualization.arrayToDataTable(" ||$taglieChart||");

        var options = {
          title: 'Distribution of the size (height + width) as in Maniaci 2012, 486.',
          curveType: 'function',
          legend: { position: 'bottom' }
        };

        var chart = new google.visualization.LineChart(document.getElementById('maniaci_chart'));

        chart.draw(data, options);
      }"


    }
    </script>,
        <div id="maniaci_chart"  class="col-md-6"
         style="height: 500px;"></div>
    )
    )
    else (<div class="col-md-6 alert alert-warning"><p>There are no outer dimensions for this selection of manuscripts.</p></div>),

    if($countmswithSSta ge 1) then (
    let $spAks:= charts:spsupport($mssAks,'Aksumite',$spvalues)
    let $spPaks1:= charts:spsupport($mssPaks1,'Post-aksumite I',$spvalues)
    let $spPaks2:= charts:spsupport($mssPaks2,'Post-aksumite 2',$spvalues)
    let $spGon:= charts:spsupport($mssGon,'Gondarine',$spvalues)
    let $spZaMe:= charts:spsupport($mssZaMe,'Zamana Masāfǝnt',$spvalues)
    let $spMoPe:= charts:spsupport($mssMoPe,'Modern Period',$spvalues)
    
    let $sp1-299:= charts:spsupport($mss1-299,'1-299',$spvalues)
    let $sp300-599:= charts:spsupport($mss300-599,'300-599',$spvalues)
    let $sp600-899:= charts:spsupport($mss600-899,'600-899',$spvalues)
    let $sp900-1199:= charts:spsupport($mss900-1199,'900-1199',$spvalues)
    let $sp1200-1499:= charts:spsupport($mss1200-1499,'1200-1499',$spvalues)
    let $sp1500-1799:= charts:spsupport($mss1500-1799,'1500-1799',$spvalues)
    let $sp1800-2099:= charts:spsupport($mss1800-2099,'1800-2099',$spvalues)
    let $spNotDated:= charts:spsupport($mssNotDated,'Not Dated',$spvalues)
    let $SewingPatterns := ($spAks, $spPaks1, $spPaks2, $spGon, $spZaMe, $spMoPe, $sp1-299, $sp300-599, $sp600-899, $sp900-1199, $sp1200-1499, $sp1500-1799, $sp1800-2099, $spNotDated)
let $headings := for $value in $spvalues return ',"' ||$value|| '"'
    let $bindingColumnChart := '[["Sewing stations" '||string-join($headings)||'],' ||string-join($SewingPatterns, ', ') || ']'
return
    (<script type="text/javascript">{'
    google.charts.load("current", {packages:["corechart"]});
    google.charts.setOnLoadCallback(drawChart);
    function drawChart() {
    var data = google.visualization.arrayToDataTable(
    '||
    $bindingColumnChart
    ||'
    );

    var view = new google.visualization.DataView(data);

    var options = { title: "Number of sewing Stations by date range for '||$countmswithSSta||' manuscripts with this type of data in the current results.",
                      isStacked: "percent",
                      height: 300,
                      legend: {position: "top", maxLines: 3},
                      vAxis: {
                        minValue: 0,
                        ticks: [0, .25, .5, .75, 1]
                      }
                    };
    var chart = new google.visualization.ColumnChart(document.getElementById("columnchart_values"));
    chart.draw(view, options);
    }'
    }
    </script>,
    <div id="columnchart_values"  class="col-md-6"
     style="height: 500px;"></div>)
  ) else (<div class="col-md-6 alert alert-warning"><p>There are no sewing stations values for this selection of manuscripts.</p></div>)
  ,

  if($countmswithSPat ge 1) then (
  
    let $spatAks:= charts:spatsupport($mssAks,'Aksumite',$spatvalues)
    let $spatPaks1:= charts:spatsupport($mssPaks1,'Post-aksumite I',$spatvalues)
    let $spatPaks2:= charts:spatsupport($mssPaks2,'Post-aksumite II',$spatvalues)
    let $spatGon:= charts:spatsupport($mssGon,'Gondarine',$spatvalues)
    let $spatZaMe:= charts:spatsupport($mssZaMe,'Zamana Masāfǝnt',$spatvalues)
    let $spatMoPe:= charts:spatsupport($mssMoPe,'Modern Period',$spatvalues)
    
  let $spat1-299:= charts:spatsupport($mss1-299,'1-299',$spatvalues)
  let $spat300-599:= charts:spatsupport($mss300-599,'300-599',$spatvalues)
  let $spat600-899:= charts:spatsupport($mss600-899,'600-899',$spatvalues)
  let $spat900-1199:= charts:spatsupport($mss900-1199,'900-1199',$spatvalues)
  let $spat1200-1499:= charts:spatsupport($mss1200-1499,'1200-1499',$spatvalues)
  let $spat1500-1799:= charts:spatsupport($mss1500-1799,'1500-1799',$spatvalues)
  let $spat1800-2099:= charts:spatsupport($mss1800-2099,'1800-2099',$spatvalues)
  let $spatNotDated:= charts:spatsupport($mssNotDated,'Not Dated',$spatvalues)
  let $SewingPatterns := ($spatAks, $spatPaks1, $spatPaks2, $spatGon, $spatZaMe, $spatMoPe, $spat1-299, $spat300-599, $spat600-899, $spat900-1199, $spat1200-1499, $spat1500-1799, $spat1800-2099, $spatNotDated)
let $headings := for $value in $spatvalues return ',"' ||$value|| '"'
  let $bindingColumnChart := '[["Sewing Patterns" '||string-join($headings)||'],' ||string-join($SewingPatterns, ', ') || ']'
return
  (<script type="text/javascript">{'
  google.charts.load("current", {packages:["corechart"]});
  google.charts.setOnLoadCallback(drawChart);
  function drawChart() {
  var data = google.visualization.arrayToDataTable(
  '||
  $bindingColumnChart
  ||'
  );

  var view = new google.visualization.DataView(data);

  var options = { title: "Sewing Patterns by date range for '||$countmswithSPat||' manuscripts with this type of data in the current results.",
                    isStacked: "percent",
                    height: 300,
                    legend: {position: "top", maxLines: 3},
                    vAxis: {
                      minValue: 0,
                      ticks: [0, .25, .5, .75, 1]
                    }
                  };
  var chart = new google.visualization.ColumnChart(document.getElementById("columnchart_SPvalues"));
  chart.draw(view, options);
  }'
  }
  </script>,
  <div id="columnchart_SPvalues"  class="col-md-6"
   style="height: 500px;"></div>)
) else (<div class="col-md-6 alert alert-warning"><p>There are no sewing pattern values for this selection of manuscripts.</p></div>)
,

if($countmswithThreadMat ge 1) then (


    let $TMAks:= charts:TMsupport($mssAks,'Aksumite',$TMvalues)
    let $TMPaks1:= charts:TMsupport($mssPaks1,'Post-aksumite I',$TMvalues)
    let $TMPaks2:= charts:TMsupport($mssPaks2,'Post-aksumite II',$TMvalues)
    let $TMGon:= charts:TMsupport($mssGon,'Gondarine',$TMvalues)
    let $TMZaMe:= charts:TMsupport($mssZaMe,'Zamana Masāfǝnt',$TMvalues)
    let $TMMoPe:= charts:TMsupport($mssMoPe,'Modern Period',$TMvalues)
    
let $TM1-299:= charts:TMsupport($mss1-299,'1-299',$TMvalues)
let $TM300-599:= charts:TMsupport($mss300-599,'300-599',$TMvalues)
let $TM600-899:= charts:TMsupport($mss600-899,'600-899',$TMvalues)
let $TM900-1199:= charts:TMsupport($mss900-1199,'900-1199',$TMvalues)
let $TM1200-1499:= charts:TMsupport($mss1200-1499,'1200-1499',$TMvalues)
let $TM1500-1799:= charts:TMsupport($mss1500-1799,'1500-1799',$TMvalues)
let $TM1800-2099:= charts:TMsupport($mss1800-2099,'1800-2099',$TMvalues)
let $TMNotDated:= charts:TMsupport($mssNotDated,'Not Dated',$TMvalues)
let $ThreadMaterials := ($TMAks, $TMPaks1, $TMPaks2, $TMGon, $TMZaMe, $TMMoPe, $TM1-299, $TM300-599, $TM600-899, $TM900-1199, $TM1200-1499, $TM1500-1799, $TM1800-2099, $TMNotDated)
let $headings := for $value in $TMvalues return ',"' ||$value|| '"'
let $bindingColumnChart :=
  '[["Thread Materials" '
  ||
  string-join($headings)
  ||
  '],'
  ||
  string-join($ThreadMaterials, ', ')
  ||
  ']'
return
(<script type="text/javascript">{'
google.charts.load("current", {packages:["corechart"]});
google.charts.setOnLoadCallback(drawChart);
function drawChart() {
var data = google.visualization.arrayToDataTable(
'||
$bindingColumnChart
||'
);

var view = new google.visualization.DataView(data);

var options = { title: "Thread Materials used by date range for '||$countmswithThreadMat||' manuscripts with this type of data in the current results.",
                  isStacked: "percent",
                  height: 300,
                  legend: {position: "top", maxLines: 3},
                  vAxis: {
                    minValue: 0,
                    ticks: [0, .25, .5, .75, 1]
                  }
                };
var chart = new google.visualization.ColumnChart(document.getElementById("columnchart_Threadvalues"));
chart.draw(view, options);
}'
}
</script>,
<div id="columnchart_Threadvalues"  class="col-md-6"
 style="height: 500px;"></div>)
) else (<div class="col-md-6 alert alert-warning"><p>There are no thread material values for this selection of manuscripts.</p></div>)
,


if($countmswithbindingMat ge 1) then (

    let $BMAks:= charts:BMsupport($mssAks,'Aksumite',$BMvalues)
    let $BMPaks1:= charts:BMsupport($mssPaks1,'Post-aksumite I',$BMvalues)
    let $BMPaks2:= charts:BMsupport($mssPaks2,'Post-aksumite II',$BMvalues)
    let $BMGon:= charts:BMsupport($mssGon,'Gondarine',$BMvalues)
    let $BMZaMe:= charts:BMsupport($mssZaMe,'Zamana Masāfǝnt',$BMvalues)
    let $BMMoPe:= charts:BMsupport($mssMoPe,'Modern Period',$BMvalues)
let $BM1-299:= charts:BMsupport($mss1-299,'1-299',$BMvalues)
let $BM300-599:= charts:BMsupport($mss300-599,'300-599',$BMvalues)
let $BM600-899:= charts:BMsupport($mss600-899,'600-899',$BMvalues)
let $BM900-1199:= charts:BMsupport($mss900-1199,'900-1199',$BMvalues)
let $BM1200-1499:= charts:BMsupport($mss1200-1499,'1200-1499',$BMvalues)
let $BM1500-1799:= charts:BMsupport($mss1500-1799,'1500-1799',$BMvalues)
let $BM1800-2099:= charts:BMsupport($mss1800-2099,'1800-2099',$BMvalues)
let $BMNotDated:= charts:BMsupport($mssNotDated,'Not Dated',$BMvalues)
let $BindingMaterials := ($BMAks, $BMPaks1, $BMPaks2, $BMGon, $BMZaMe, $BMMoPe, $BM1-299, $BM300-599, $BM600-899, $BM900-1199, $BM1200-1499, $BM1500-1799, $BM1800-2099, $BMNotDated)
let $headings := for $value in $BMvalues return ',"' ||$value|| '"'
let $bindingColumnChart :=
  '[["Thread Materials" '
  ||
  string-join($headings)
  ||
  '],'
  ||
  string-join($BindingMaterials, ', ')
  ||
  ']'
return
(<script type="text/javascript">{'
google.charts.load("current", {packages:["corechart"]});
google.charts.setOnLoadCallback(drawChart);
function drawChart() {
var data = google.visualization.arrayToDataTable(
'||
$bindingColumnChart
||'
);

var view = new google.visualization.DataView(data);

var options = { title: "Binding Materials used by date range  for '||$countmswithbindingMat||' manuscripts with this type of data in the current results.",
                  isStacked: "percent",
                  height: 300,
                  legend: {position: "top", maxLines: 3},
                  vAxis: {
                    minValue: 0,
                    ticks: [0, .25, .5, .75, 1]
                  }
                };
var chart = new google.visualization.ColumnChart(document.getElementById("columnchart_BMvalues"));
chart.draw(view, options);
}'
}
</script>,
<div id="columnchart_BMvalues"  class="col-md-6"
 style="height: 500px;"></div>)
) else (<div class="col-md-6 alert alert-warning"><p>There are no binding material values for this selection of manuscripts.</p></div>)
,

if($countmsObjTyp ge 1) then (


    let $OTAks:= charts:OTsupport($mssAks,'Aksumite',$OTvalues)
    let $OTPaks1:= charts:OTsupport($mssPaks1,'Post-aksumite I',$OTvalues)
    let $OTPaks2:= charts:OTsupport($mssPaks2,'Post-aksumite II',$OTvalues)
    let $OTGon:= charts:OTsupport($mssGon,'Gondarine',$OTvalues)
    let $OTZaMe:= charts:OTsupport($mssZaMe,'Zamana Masāfǝnt',$OTvalues)
    let $OTMoPe:= charts:OTsupport($mssMoPe,'Modern Period',$OTvalues)
let $OT1-299:= charts:OTsupport($mss1-299,'1-299',$OTvalues)
let $OT300-599:= charts:OTsupport($mss300-599,'300-599',$OTvalues)
let $OT600-899:= charts:OTsupport($mss600-899,'600-899',$OTvalues)
let $OT900-1199:= charts:OTsupport($mss900-1199,'900-1199',$OTvalues)
let $OT1200-1499:= charts:OTsupport($mss1200-1499,'1200-1499',$OTvalues)
let $OT1500-1799:= charts:OTsupport($mss1500-1799,'1500-1799',$OTvalues)
let $OT1800-2099:= charts:OTsupport($mss1800-2099,'1800-2099',$OTvalues)
let $OTNotDated:= charts:OTsupport($mssNotDated,'Not Dated',$OTvalues)
let $supports := ($OTAks, $OTPaks1, $OTPaks2, $OTGon, $OTZaMe, $OTMoPe, $OT1-299, $OT300-599, $OT600-899, $OT900-1199, $OT1200-1499, $OT1500-1799, $OT1800-2099, $OTNotDated)
let $headings := for $value in $OTvalues return ',"' ||$value|| '"'
let $bindingColumnChart :=
  '[["Form of support" '
  ||
  string-join($headings)
  ||
  '],'
  ||
  string-join($supports, ', ')
  ||
  ']'
return
(<script type="text/javascript">{'
google.charts.load("current", {packages:["corechart"]});
google.charts.setOnLoadCallback(drawChart);
function drawChart() {
var data = google.visualization.arrayToDataTable(
'||
$bindingColumnChart
||'
);

var view = new google.visualization.DataView(data);

var options = { title: "Form of support used by date range for '||$countmsObjTyp||' manuscripts with this type of data in the current results.",
                  isStacked: "percent",
                  height: 300,
                  legend: {position: "top", maxLines: 3},
                  vAxis: {
                    minValue: 0,
                    ticks: [0, .25, .5, .75, 1]
                  }
                };
var chart = new google.visualization.ColumnChart(document.getElementById("columnchart_OTvalues"));
chart.draw(view, options);
}'
}
</script>,
<div id="columnchart_OTvalues"  class="col-md-6"
 style="height: 500px;"></div>)
) else (<div class="col-md-6 alert alert-warning"><p>There are no object form values for this selection of manuscripts.</p></div>)
,
if($countmswithMainMat ge 1) then (

    let $MMAks:= charts:MMsupport($mssAks,'Aksumite',$MMvalues)
    let $MMPaks1:= charts:MMsupport($mssPaks1,'Post-aksumite I',$MMvalues)
    let $MMPaks2:= charts:MMsupport($mssPaks2,'Post-aksumite II',$MMvalues)
    let $MMGon:= charts:MMsupport($mssGon,'Gondarine',$MMvalues)
    let $MMZaMe:= charts:MMsupport($mssZaMe,'Zamana Masāfǝnt',$MMvalues)
    let $MMMoPe:= charts:MMsupport($mssMoPe,'Modern Period',$MMvalues)
let $MM1-299:= charts:MMsupport($mss1-299,'1-299',$MMvalues)
let $MM300-599:= charts:MMsupport($mss300-599,'300-599',$MMvalues)
let $MM600-899:= charts:MMsupport($mss600-899,'600-899',$MMvalues)
let $MM900-1199:= charts:MMsupport($mss900-1199,'900-1199',$MMvalues)
let $MM1200-1499:= charts:MMsupport($mss1200-1499,'1200-1499',$MMvalues)
let $MM1500-1799:= charts:MMsupport($mss1500-1799,'1500-1799',$MMvalues)
let $MM1800-2099:= charts:MMsupport($mss1800-2099,'1800-2099',$MMvalues)
let $MMNotDated:= charts:MMsupport($mssNotDated,'Not Dated',$MMvalues)
let $MainMaterials := ($MMAks, $MMPaks1, $MMPaks2, $MMGon, $MMZaMe, $MMMoPe, $MM1-299, $MM300-599, $MM600-899, $MM900-1199, $MM1200-1499, $MM1500-1799, $MM1800-2099, $MMNotDated)
let $headings := for $value in $MMvalues return ',"' ||$value|| '"'
let $bindingColumnChart :=
  '[["Material" '
  ||
  string-join($headings)
  ||
  '],'
  ||
  string-join($MainMaterials, ', ')
  ||
  ']'
return
(<script type="text/javascript">{'
google.charts.load("current", {packages:["corechart"]});
google.charts.setOnLoadCallback(drawChart);
function drawChart() {
var data = google.visualization.arrayToDataTable(
'||
$bindingColumnChart
||'
);

var view = new google.visualization.DataView(data);

var options = { title: "Support Materials used by date range  for '||$countmswithMainMat||' manuscripts with this type of data in the current results.",
                  isStacked: "percent",
                  height: 300,
                  legend: {position: "top", maxLines: 3},
                  vAxis: {
                    minValue: 0,
                    ticks: [0, .25, .5, .75, 1]
                  }
                };
var chart = new google.visualization.ColumnChart(document.getElementById("columnchart_MMvalues"));
chart.draw(view, options);
}'
}
</script>,
<div id="columnchart_MMvalues"  class="col-md-6"
 style="height: 500px;"></div>)
) else (<div class="col-md-6 alert alert-warning"><p>There are no support material values for this selection of manuscripts.</p></div>)
,

if($countRulPat ge 1) then (
let $patterns := for $ruling in $rulingpattern return <mss><id>{string($ruling/ancestor::t:TEI/@xml:id)}</id><pattern>{analyze-string($ruling, '(([A-Z\d\-]+)/([A-Z\d\-]+)/([A-Z\d\-]+)/([A-Z\d\-]+))')}</pattern></mss>
let $fullpatterns := for $p in $patterns//s:group[@nr=1] return string-join($p//text())
let $verticals:= $patterns//s:group[@nr=2]
let $Hmarginals:= $patterns//s:group[@nr=3]
let $RectricesMajs:= $patterns//s:group[@nr=4]
let $Rectrices:= $patterns//s:group[@nr=5]
return (
(:pie total diversity distribution:)
let $distinct-patterns:= distinct-values($fullpatterns)
let $matcher := for $p in $patterns return string-join($p//s:group[@nr=1]//text())
let $data := for $pat in $distinct-patterns
                let $count := count($matcher[.=$pat])
                 return
                               '["' ||  $pat || '", ' ||  $count || ']'
let $patts := '[["Ruling Pattern","Quantity"],' ||string-join($data, ', ') || ']'

    return
    (<script type="text/javascript">
    {'google.charts.load("current", {packages:["corechart"]});
      google.charts.setOnLoadCallback(drawChart);
      function drawChart() {
        var data = google.visualization.arrayToDataTable(' ||
        $patts
       || ");

        var options = {
          title: 'Diversity of Ruling Pattern on "||$countRulPat||" manuscripts, based on ANALYSE DES RÉGLURES by D. MUZERELLE.',
          is3D: true,
        };

        var chart = new google.visualization.PieChart(document.getElementById('piechart_ruling'));
        chart.draw(data, options);
      }"

      }

    </script>,
    <div id="piechart_ruling" class="col-md-6"
     style="height: 500px;"/>
    )
    ,
 for $formulaZone in 2 to 5 return

(:column charts:)

        (: Zone I = 2= verticals:)
        
        (: ZoneII = 3= Horizontal marginals:)
        
        (: Zone III = 4=Rectrices Majeures :)
        
        (: Zone IV = 5=Rectices       :)
        let $RPZvalues := distinct-values($patterns//s:group[@nr=$formulaZone])
        let $formulaZoneName := 
                        switch($formulaZone) 
                        case 2 return 'Zone I (Verticales)'
                        case 3 return 'Zone II (Horizontales marginales)'
                        case 4 return 'Zone III (Rectrices majeures)'
                        case 5 return 'Zone IV (Rectrices)' 
                        default return ''
      let $RPZAks:= charts:RulingSupport($mssAks,'Aksumite',$RPZvalues, $formulaZone)
    let $RPZPaks1:= charts:RulingSupport($mssPaks1,'Post-aksumite I',$RPZvalues, $formulaZone)
    let $RPZPaks2:= charts:RulingSupport($mssPaks2,'Post-aksumite II',$RPZvalues, $formulaZone)
    let $RPZGon:= charts:RulingSupport($mssGon,'Gondarine',$RPZvalues, $formulaZone)
    let $RPZZaMe:= charts:RulingSupport($mssZaMe,'Zamana Masāfǝnt',$RPZvalues, $formulaZone)
    let $RPZMoPe:= charts:RulingSupport($mssMoPe,'Modern Period',$RPZvalues, $formulaZone)
let $RPZ1-299:= charts:RulingSupport($mss1-299,'1-299',$RPZvalues, $formulaZone)
let $RPZ300-599:= charts:RulingSupport($mss300-599,'300-599',$RPZvalues, $formulaZone)
let $RPZ600-899:= charts:RulingSupport($mss600-899,'600-899',$RPZvalues, $formulaZone)
let $RPZ900-1199:= charts:RulingSupport($mss900-1199,'900-1199',$RPZvalues, $formulaZone)
let $RPZ1200-1499:= charts:RulingSupport($mss1200-1499,'1200-1499',$RPZvalues, $formulaZone)
let $RPZ1500-1799:= charts:RulingSupport($mss1500-1799,'1500-1799',$RPZvalues, $formulaZone)
let $RPZ1800-2099:= charts:RulingSupport($mss1800-2099,'1800-2099',$RPZvalues, $formulaZone)
let $RPZNotDated:= charts:RulingSupport($mssNotDated,'Not Dated',$RPZvalues, $formulaZone)
let $RulingPatterns := ($RPZAks, $RPZPaks1, $RPZPaks2, $RPZGon, $RPZZaMe, $RPZMoPe, $RPZ1-299, $RPZ300-599, $RPZ600-899, $RPZ900-1199, $RPZ1200-1499, $RPZ1500-1799, $RPZ1800-2099, $RPZNotDated)
let $headings := for $value in $RPZvalues return ',"' ||$value|| '"'
let $RPZColumnChart :=
  '[["Ruling Pattern '||$formulaZoneName||'" '
  ||
  string-join($headings)
  ||
  '],'
  ||
  string-join($RulingPatterns, ', ')
  ||
  ']'
return
(<script type="text/javascript">{'
google.charts.load("current", {packages:["bar"]});
google.charts.setOnLoadCallback(drawChart);
function drawChart() {
var data = google.visualization.arrayToDataTable(
'||
$RPZColumnChart
||'
);

var view = new google.visualization.DataView(data);

var options = { title: "Ruling pattern '||$formulaZoneName||' by date range  for '||$countRulPat||' patterns registered in the current results."
                 
                };
var chart = new google.visualization.ColumnChart(document.getElementById("columnchart_ruling'||$formulaZone||'"));
chart.draw(data, google.charts.Bar.convertOptions(options));
}'
}
</script>,
<div id="columnchart_ruling{$formulaZone}"  class="col-md-6"
 style="height: 500px;"></div>)
        
)
   
) else (<div class="col-md-6 alert alert-warning"><p>There are no Ruling Patterns for this selection of manuscripts.</p></div>)
,
if($countLayout ge 1) then (

  let $dims := for $d in $layoutdimensions
               let $all := $d/t:dimensions
               let $SM := $d/ancestor::t:TEI//t:msIdentifier/t:idno/text()
               let $title := titles:printTitle($d)
               let $h := if($all/t:height/text()) then string-join($all/t:height/text(), ' ') else '0'
               let $w := if($all/t:width/text()) then string-join($all/t:width/text(), ' ') else '0'
               let $writtenlines := if($d/@writtenLines) then if(contains($d/@writtenLines, ' ')) then let $dims := for $x in tokenize($d/@writtenLines, ' ') return number($x) return avg($dims) else $d/@writtenLines else '0'
               return
                 '["'||$SM||'",'||$w||','||$h||',"'||$title||'", '||$writtenlines||']'

    let $dimensionsTable := '[["shelf mark","widht","height","title","written lines"],
    ' ||string-join($dims, ',
    ') || ']'

    return
    (
    <script type="text/javascript">
      {'google.charts.load("current", {"packages":["corechart"]});
      google.charts.setOnLoadCallback(drawSeriesChart);

    function drawSeriesChart() {

      var data = google.visualization.arrayToDataTable(
      '||$dimensionsTable||'
      );

      var options = {
        title: "Ratio of writing area dimensions of the ' ||$countLayout||' manuscripts which have layout dimensions recorded. One bubble for each such layout encoded, so, possibly more then one for each manuscript. ",
        hAxis: {title: "width"},
        vAxis: {title: "height"},
        bubble: {textStyle: {fontSize: 11}}
      };

      var chart = new google.visualization.BubbleChart(document.getElementById("series_chart_div_layout"));
      chart.draw(data, options);
    }
    '}
    </script>,
    <div id="series_chart_div_layout"  class="col-md-6"
     style="height: 500px;"></div>

    )
    )
    else (<div  class="col-md-6 alert alert-warning"><p>There are no manuscript with layout dimensions for this selection of manuscripts.</p></div>)
  )
 };


declare function  charts:tagliasupport($mssDate, $totcount, $from, $to){
 let  $mssDateTaglias := for $ms in $mssDate//t:extent[descendant::t:dimensions[@type='outer'][t:height][t:width][t:depth]]
                                                                     let $all := $ms/t:dimensions[@type='outer']
                                                                    let $h := if($all/t:height/text()) then string-join($all/t:height/text(), ' ') else '0'
               let $w := if($all/t:width/text()) then string-join($all/t:width/text(), ' ') else '0'
               let $realtaglia := number($h) + number($w)
                                                                   return if((number($realtaglia) ge $from) and (number($realtaglia) le $to)) then 1 else 0
                                             let $mssDateThisTaglia := sum($mssDateTaglias)
                                              let $div := ($mssDateThisTaglia div $totcount)
                                             return format-number($div, "#.#%")
                                              };

declare function charts:spsupport($mss, $rangeName, $values){
  let $mssthisperiod:= $mss//t:decoNote[@type='SewingStations']
  return
  if(count($mssthisperiod) eq 0) then () else
  let $total := count($mssthisperiod)
  let $columns := for $value in $values
                  let $countms := count($mssthisperiod[. = $value])
                  let $div := ($countms div $total)
                  let $perc := format-number($div, "#.#%")
                  return ',' ||$perc
  return
    '["'||$rangeName||'"'||string-join($columns)||']'

};

declare function charts:spatsupport($mss, $rangeName, $values){
  let $mssthisperiod:= $mss//t:decoNote[t:term[contains(@key, 'pattern')]]
  return
  if(count($mssthisperiod) eq 0) then () else
  let $total := count($mssthisperiod)
  let $columns := for $value in $values
                  let $countms := count($mssthisperiod/t:term[@key = $value])
                  let $div := ($countms div $total)
                  let $perc := format-number($div, "#.#%")
                  return ',' ||$perc
  return
    '["'||$rangeName||'"'||string-join($columns)||']'

};

declare function charts:TMsupport($mss, $rangeName, $values){
  let $mssthisperiod:= $mss//t:decoNote[t:term[ends-with(@key, 'Thread') or contains(@key, 'tannedSkin')]]
  return
  if(count($mssthisperiod) eq 0) then () else
  let $total := count($mssthisperiod)
  let $columns := for $value in $values
                  let $countms := count($mssthisperiod/t:term[@key = $value])
                  let $div := ($countms div $total)
                  let $perc := format-number($div, "#.#%")
                  return ',' ||$perc
  return
    '["'||$rangeName||'"'||string-join($columns)||']'

};

declare function charts:BMsupport($mss, $rangeName, $values){
  let $mssthisperiod:= $mss//t:decoNote[parent::t:binding][t:material]
  return
  if(count($mssthisperiod) eq 0) then () else
  let $total := count($mssthisperiod)
  let $columns := for $value in $values
                  let $countms := count($mssthisperiod/t:material[@key = $value])
                  let $div := ($countms div $total)
                  let $perc := format-number($div, "#.#%")
                  return ',' ||$perc
  return
    '["'||$rangeName||'"'||string-join($columns)||']'

};

declare function charts:MMsupport($mss, $rangeName, $values){
  let $mssthisperiod:= $mss//t:support[t:material]
  return
  if(count($mssthisperiod) eq 0) then () else
  let $total := count($mssthisperiod)
  let $columns := for $value in $values
                  let $countms := count($mssthisperiod/t:material[@key = $value])
                  let $div := ($countms div $total)
                  let $perc := format-number($div, "#.#%")
                  return ',' ||$perc
  return
    '["'||$rangeName||'"'||string-join($columns)||']'

};


declare function charts:OTsupport($mss, $rangeName, $values){
  let $mssthisperiod:= $mss//t:objectDesc
  return
  if(count($mssthisperiod) eq 0) then () else
  let $total := count($mssthisperiod)
  let $columns := for $value in $values
                  let $countms := count($mssthisperiod[@form = $value])
                  let $div := ($countms div $total)
                  let $perc := format-number($div, "#.#%")
                  return ',' ||$perc
  return
    '["'||$rangeName||'"'||string-join($columns)||']'

};

declare function charts:RulingSupport($DatedMSS, $rangeName, $values, $formulaZone){
  let $mssthisperiod:= $DatedMSS//t:ab[@type="ruling"][@subtype="pattern"]
  let $patterns := for $ruling in $mssthisperiod return 
  <mss>
  <id>{string($ruling/ancestor::t:TEI/@xml:id)}</id>
  <pattern>{analyze-string($ruling, '(([A-Z\d\-]+)/([A-Z\d\-]+)/([A-Z\d\-]+)/([A-Z\d\-]+))')}</pattern>
  </mss>

  return
  if(count($mssthisperiod) eq 0) then () else
  let $columns := for $value in $values
                  let $countms := count($patterns[descendant::s:group[@nr=$formulaZone][. = $value]])
                  return ',' ||$countms
  return
    '["'||$rangeName||'"'||string-join($columns)||']'

};
