xquery version "3.0";

declare namespace http="http://expath.org/ns/http-client";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace console = "http://exist-db.org/xquery/console";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "titles.xqm";
import module namespace coord="https://www.betamasaheft.uni-hamburg.de/BetMas/coord" at "coordinates.xql";

declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace dcterms = "http://purl.org/dc/terms";
declare namespace saws = "http://purl.org/saws/ontology";
declare namespace cmd = "http://www.clarin.eu/cmd/";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace s = "http://www.w3.org/2005/xpath-functions";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";
declare namespace jmx="http://exist-db.org/jmx";

 
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html5";
declare option output:omit-xml-declaration "no";
declare option output:media-type "text/html";

declare function local:MAP(){
let $map :=
<map>{
    let $settings : =
<setting>

var mbAttr = 'Map data © OpenStreetMap contributors, ' +
			'CC-BY-SA, ' +
			'Imagery © Mapbox',
		mbUrl = 'https://api.tiles.mapbox.com/v4/{{id}}/{{z}}/{{x}}/{{y}}.png?access_token=pk.eyJ1IjoicGlldHJvbGl1enpvIiwiYSI6ImNpbDB6MjE0bDAwOGl4MW0wa2JvMDd0cHMifQ.wuV3-VuvmCzY69kWRf6CHA';
                                     
	var grayscale   = L.tileLayer(mbUrl, {{id: 'mapbox.light', attribution: mbAttr}}),
		streets  = L.tileLayer(mbUrl, {{id: 'mapbox.streets',   attribution: mbAttr}});
		satellite = L.tileLayer(mbUrl, {{id: 'mapbox.satellite',   attribution: mbAttr}});
		outdoor = L.tileLayer(mbUrl, {{id: 'mapbox.outdoors',   attribution: mbAttr}});
            
        </setting>


let $data := 

    <placesWithCoord>
    {
let $collections := ($config:data-rootIn, $config:data-rootPl)
let $tei := collection($collections)/t:TEI
let $teiwithcoord := $tei[descendant::t:geo[text()] or descendant::t:place[@sameAs]]
return 
for $place in subsequence($teiwithcoord, 1,20)
let $id := string($place/@xml:id)
let $corresps := collection($config:data-rootMS)//t:repository[@ref = $id] 

     return 
     <place>
     <id>{$id}</id>
     {for $t in tokenize($place//t:place/@type,  ' ')
     return
     <type type="{$t}"/>}
     {for $t in tokenize($place//t:place/@subtype,  ' ')
     return
     <type type="{$t}"/>}
     <name>{replace(titles:printTitle($place), "'", '´')}</name>
     <coord>{coord:getCoords($id)}</coord>
     {if ($place//t:height) then <alt>{$place//t:height/text()}</alt> else()}
     {
     if ($corresps) then (for $corr in $corresps return <mss>{data(root($corr)/t:TEI/@xml:id)}</mss>)
     else if ($place//t:ref[@type='mss']) then for $ref in  $place//t:ref[@type='mss']/@corresp return <mss>{data($ref)}</mss> 
     else ()}
     </place>
        (: take also mss from here looking at ref[@type='mss']:)
    }
    </ placesWithCoord>
    
    let $style := <style>
    var colPoint = '#000';
    var colPlace = 'rgb(172, 230, 0)';
    var colIns = 'rgb(255, 212, 128)';
    var styleplace = {{ color: colPoint, fillColor: colPlace, radius: 5, opacity: 0.5, fillOpacity: 0.7 }};
    var styleinstitution = {{ color: colPoint, fillColor: colIns, radius: 10, opacity: 0.5, fillOpacity: 0.5 }};
    
    </style>
   let $basemap :=
   <ba>
   var baseLayers = {{
		"Altitude": outdoor,
		"Grayscale": grayscale,
		"Satellite": satellite,
		"Streets": streets
	}};
	
			  </ba>
   

return 
<mapdata>
    <setting>{$settings/text()}
                </setting>
                <layers>
                {
                for $type in distinct-values($data//type/@type[.!=''])
                return 
                ('var ' || $type || '= new L.LayerGroup(); 
                ' )
                }
                </layers>
                <style>{$style}</style>
    <data>
    {for $place at $pos in $data//place
     let $seq := for $point in tokenize($place//coord, ' ') return $point
    let $coordtype := if((count($seq) gt 1) and ($seq[last()] = $seq[1])) then('polygon') else ('point')
  let $types :=  <type>{for $t in $place//type return <i>{('.addTo(' ||data($t/@type[.!='']) || ')')}</i>}</type>
                let $mss := <mss>{for $ms in $place//mss order by $ms return <m>{('<li><a  target="_blank" href="' || $ms|| '">' || replace((collection($config:data-rootMS)//t:TEI/id($ms)//t:msIdentifier[1]/t:idno[1])[1], "'", '') ||'</a></li> ')}</m>}</mss>
               let $count := count($data//place)
    return
                if ($place//type/@type = 'institution') then ('
                L.circleMarker([' || replace($place/coord, ' ', ', ') ||"], styleinstitution).bindPopup('"||'<a target="_blank" href="' || $place/id|| '">' || $place/name ||'</a> <br><b>Check in:</b> <a href="http://pleiades.stoa.org/search?SearchableText='||$place/name || '" target="_blank">Pleiades</a>; <a href="https://en.wikipedia.org/wiki/Special:Search/'||$place/name||'" target="_blank">Wikipedia</a>' || (if ($place/mss) then (' </br> Manuscripts here: <ul>' || $mss || '<ul>') else ()) || "')"  || $types
                 || (if ($pos = $count) then '' else ',' ))

else if($coordtype = 'polygon') then ('L.polygon(['||
                (let $points:= for $point in $seq
                        return 
                        '['||$point||']'
                return (string-join($points, ','), console:log(string-join($points, ',')))) ||
                
"], styleplace).bindPopup('" || '<a target="_blank" href="' || $place/id|| '">' || $place/name ||'</a> <br><b>Check in:</b> <a href="http://pleiades.stoa.org/search?SearchableText='||$place/name || '" target="_blank">Pleiades</a>; <a href="https://en.wikipedia.org/wiki/Special:Search/'||$place/name||'" target="_blank">Wikipedia</a>' || "')"  || $types) 
else('
                L.circleMarker([' || replace($place/coord, ' ', ', ') ||"], styleplace).bindPopup('"||'<a target="_blank" href="' || $place/id|| '">' || $place/name ||'</a> <br><b>Check in:</b> <a href="http://pleiades.stoa.org/search?SearchableText='||$place/name || '" target="_blank">Pleiades</a>; <a href="https://en.wikipedia.org/wiki/Special:Search/'||$place/name||'" target="_blank">Wikipedia</a>' || (if ($place/mss) then (' </br> Manuscripts here: <ul>' || $mss || '<ul>') else ()) || "')"  || $types
                 || (if ($pos = $count) then '' else ',' ))
    

    }
    </data>
    <base>{$basemap}</base>
    <overlay> 
  {let $types :=  
                <type>{for $t in distinct-values($data//place/type/@type) return <i>{' '|| (data($t)||',')}</i>}</type>
     let $overlays := <over>{for $t in distinct-values($data//place/type/@type[.!='']) return <i>{('
     "' ||upper-case(data($t))||'": ' || data($t)||',')}</i>}</over>
     let $legend := '<i style="background: rgb(255, 212, 128)"></i> repositories <br></br> <i style="background: rgb(172, 230, 0)"></i> places'
     return       
    "
        var map = L.map('map', {
		center: [10.5500, 39.2833],
		zoom: 6,
		layers: [outdoor, " || replace($types,',$','') || " ],
        fullscreenControl: true,
        // OR 
        fullscreenControl: {
        pseudoFullscreen: false // if true, fullscreen to page width and height
        }
	});

var legend = L.control({position: 'bottomright'});

legend.onAdd = function (map) {

    var div = L.DomUtil.create('div', 'info legend')

        div.innerHTML += '"||$legend||"' 
    

    return div;
};

legend.addTo(map);

	var overlays = {"
||
replace($overlays,',$','')
||		
"};
      "}
      
            </overlay>
            <control>
                L.control.layers(baseLayers, overlays).addTo(map);
                </control>
            
</mapdata> 
}
</map>

return

$map//text()

};


<html>
    <head>
        <link href="https://api.mapbox.com/mapbox.js/v2.3.0/mapbox.css" rel="stylesheet"></link>
        <link rel="stylesheet" href="http://cdn.leafletjs.com/leaflet/v0.7.7/leaflet.css"></link>
        <link rel="stylesheet" href="https://api.mapbox.com/mapbox.js/plugins/leaflet-fullscreen/v1.0.1/leaflet.fullscreen.css"></link>
        <link href="https://maxcdn.bootstrapcdn.com/bootswatch/3.3.7/flatly/bootstrap.min.css" rel="stylesheet" integrity="sha384-+ENW/yibaokMnme+vBLnHMphUYxHs34h9lpdbSLuAwGkOKFRl4C34WkjazBtb7eT" crossorigin="anonymous"></link>
        <script type="text/javascript" src="https://code.jquery.com/jquery-1.11.1.min.js"></script>
        <script src="http://cdn.leafletjs.com/leaflet/v0.7.7/leaflet.js" type="text/javascript"></script>
        <script src="https://api.mapbox.com/mapbox.js/v2.3.0/mapbox.js" type="text/javascript"></script>
        <script src="https://api.mapbox.com/mapbox.js/plugins/leaflet-fullscreen/v1.0.1/Leaflet.fullscreen.min.js" type="text/javascript"></script>
        <script type="text/javascript" src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js" integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa" crossorigin="anonymous"></script>
        </head>
    
    <body id="body">
        
        <div id="content" class="container-fluid col-md-12">
    <div class="col-md-6">
        <div class="page-header">
            <h1>Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</h1>
        </div>
    </div>
    <div class="row-fluid">
      
                <div id="map" class="tab-pane fade in active"></div>
            <script type="text/javascript">
            {local:MAP()}
            </script>
            
        </div>
    
</div>
        
        
    </body>
</html>

