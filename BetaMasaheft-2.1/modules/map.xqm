xquery version "3.0" encoding "UTF-8";

module namespace BetMasMap="https://www.betamasaheft.uni-hamburg.de/BetMas/map";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "titles.xqm";
import module namespace app="https://www.betamasaheft.uni-hamburg.de/BetMas/app" at "app.xqm";
import module namespace coord="https://www.betamasaheft.uni-hamburg.de/BetMas/coord" at "coordinates.xql";
import module namespace console = "http://exist-db.org/xquery/console";
declare namespace t="http://www.tei-c.org/ns/1.0";
declare option exist:serialize "method=text mediatype=text/javascript";


(:this does not use geoJson:)
declare function BetMasMap:MAP($node as node(), $model as map(*)){
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
let $collection := collection($collections)
let $tei := $collection/t:TEI
return 
for $place in $tei[descendant::t:geo[text()]]
let $id := string($place/@xml:id)
let $corresps := collection($config:data-rootMS)//t:repository[@ref = $id] 

     return 
     <place>
     <id>{data($place/@xml:id)}</id>
     {for $t in tokenize($place//t:place/@type,  ' ')
     return
     <type type="{$t}"/>}
     {for $t in tokenize($place//t:place/@subtype,  ' ')
     return
     <type type="{$t}"/>}
     <name>{replace(titles:printTitle($place), "'", '´')}</name>
     <coord>{$place//t:geo/text()}</coord>
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
                let $types :=  
                <type>{for $t in $place//type return <i>{('.addTo(' ||data($t/@type[.!='']) || ')')}</i>}</type>
                let $mss := <mss>{for $ms in $place//mss order by $ms return <m>{('<li><a  target="_blank" href="' || $ms|| '">' || replace((collection($config:data-rootMS)//t:TEI/id($ms)//t:msIdentifier[1]/t:idno[1])[1], "'", '') ||'</a></li> ')}</m>}</mss>
               let $count := count($data//place)
    return
                if ($place//type/@type = 'institution') then ('
                L.circleMarker([' || replace($place/coord, ' ', ', ') ||"], styleinstitution).bindPopup('"||'<a target="_blank" href="' || $place/id|| '">' || $place/name ||'</a> <br><b>Check in:</b> <a href="http://pleiades.stoa.org/search?SearchableText='||$place/name || '" target="_blank">Pleiades</a>; <a href="https://en.wikipedia.org/wiki/Special:Search/'||$place/name||'" target="_blank">Wikipedia</a>' || (if ($place/mss) then (' </br> Manuscripts here: <ul>' || $mss || '<ul>') else ()) || "')"  || $types
                 || (if ($pos = $count) then '' else ',' ))
                 else ('
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

(:this does not use geoJson:)
declare function BetMasMap:entityMap($node as node(), $model as map(*)){
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
        let $itemid := $model('entity')/@xml:id
let $placeInstpointingHere := app:WhatPointsHere(string($itemid))
let $refPlaceInstpointingHere := for $rip in $placeInstpointingHere return collection($config:data-rootIn, $config:data-rootPl)//id(root($rip))


let $reftoplacesHere := ($model('entity')//t:placeName[@ref], $model('entity')//t:region[@ref], $model('entity')//t:settlement[@ref], $model('entity')//t:country[@ref])
let $refPlacesRecords := for $rp in $reftoplacesHere/@ref return if(starts-with($rp, 'gn:')) then doc(concat('http://api.geonames.org/get?geonameId=',$rp,'&amp;username=betamasaheft'))//geoname else doc((($config:data-rootPl) || '/' ||$rp|| '.xml'))/t:TEI


let $reftoinstHere := $model('entity')//t:repository[@ref]
let $refInstitutionRecords := for $ri in $reftoinstHere/@ref return collection($config:data-rootIn)//id($ri)


for $place in ($refPlacesRecords[.//t:geo or .//coordinates], $refInstitutionRecords[.//t:geo], $refPlaceInstpointingHere[.//t:geo])


     return 
     if ($place/@xml:id) then(
     let $id := string($place/@xml:id) return
     <place>
     <id>{data($place/@xml:id)}</id>
     {for $t in tokenize($place//t:place/@type,  ' ')
     return
     <type type="{$t}"/>}
     {for $t in tokenize($place//t:place/@subtype,  ' ')
     return
     <type type="{$t}"/>}
     <name>{replace(titles:printTitle($place), "'", '´')}</name>
     <coord>{$place//t:geo/text()}</coord>
     {if ($place//t:height) then <alt>{$place//t:height/text()}</alt> else()}
     </place>)
        (: take also mss from here looking at ref[@type='mss']:)
        
        else
        (
     <place>
     <id>{data($place/geonameId)}</id>
     {for $t in tokenize($place//t:fclName,  ', ')
     return
     <type type="{$t}"/>}
     
     <name>{$place/toponymName}</name>
     <coord>{if ($place/coordinates) then $place/coordinates else $place/bbox}</coord>
     {if ($place//t:height) then <alt>{$place/t:elevation}</alt> else()}
     </place>)
        
    }
    </ placesWithCoord>
    
    let $style := <style>
    var colPoint1 = '#000';
			var colPoint2 = 'green';
			var style = {{ color: colPoint1, fillColor: colPoint2, radius: 8, opacity: 0.5, fillOpacity: 0.5 }};
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
                for $type in distinct-values($data//type/@type)
                return 
                ('var ' || $type || '= new L.LayerGroup(); 
                ' )
                }
                </layers>
                <style>{$style}</style>
    <data>
    {for $place at $pos in $data//place
                let $types :=  
                <type>{for $t in $place//type return <i>{('.addTo(' ||data($t/@type) || ')')}</i>}</type>
                let $mss := <mss>{for $ms in $place//mss order by $ms return <m>{('<li><a  target="_blank" href="' || $ms|| '">' || $ms ||'</a></li> ')}</m>}</mss>
               
    return
                ('
                L.circleMarker([' || replace($place/coord, ' ', ', ') ||"], style).bindPopup('"||'<a target="_blank" href="' || $place/id|| '">' || $place/name ||'</a> <br><b>Check in:</b> <a href="http://pleiades.stoa.org/search?SearchableText='||$place/name || '" target="_blank">Pleiades</a>; <a href="https://en.wikipedia.org/wiki/Special:Search/'||$place/name||'" target="_blank">Wikipedia</a>' || (if ($place/mss) then (' </br> Manuscripts here: <ul>' || $mss || '<ul>') else ()) || "')"  || $types
                 || (if ($pos = count($data//place)) then '' else ',' ))
    

    }
    </data>
    <base>{$basemap}</base>
    <overlay> 
  {let $types :=  
                <type>{for $t in distinct-values($data//place/type/@type) return <i>{' '|| (data($t)||',')}</i>}</type>
     let $overlays := <over>{for $t in distinct-values($data//place/type/@type) return <i>{('
     "' ||upper-case(data($t))||'": ' || data($t)||',')}</i>}</over>
     
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

declare function BetMasMap:RestMAP(){

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
    {let $collections := ($config:data-rootIn, $config:data-rootPl)
let $collection := collection($collections)
let $ms := collection($config:data-rootMS)
let $tei := $collection/t:TEI
return 
for $document in $tei[descendant::t:geo[text()] or descendant::t:place[@sameAs]]
let $id := string($document/@xml:id)
let $corresps := $ms//t:repository[@ref = $id] 
return

   
     <place>
     <id>{$id}</id>
     {for $t in tokenize($document//t:place/@type,  ' ')
     return
     <type type="{$t}"/>}
     {for $t in tokenize($document//t:place/@subtype,  ' ')
     return
     <type type="{$t}"/>}
     <name>{replace(titles:printTitleID($id), "'", '´')}</name>
     <coord>{coord:getCoords($id)}</coord>
     {if ($document//t:height) then <alt>{$document//t:height/text()}</alt> else()}
     </place>
}</placesWithCoord>
    
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
                for $type in distinct-values($data//type/@type)
                return 
                ('var ' || $type || '= new L.LayerGroup(); 
                ' )
                }
                </layers>
                <style>{$style}</style>
    <data>
    {for $place at $pos in $data//place
                let $types :=  
                <type>{for $t in $place//type return <i>{('.addTo(' ||data($t/@type[.!='']) || ')')}</i>}</type>
                let $mss := <mss>{for $ms in $place//mss order by $ms return <m>{('<li><a  target="_blank" href="' || $ms|| '">' || replace((collection($config:data-rootMS)//t:TEI/id($ms)//t:msIdentifier[1]/t:idno[1])[1], "'", '') ||'</a></li> ')}</m>}</mss>
               let $count := count($data//place)
    return
                if ($place//type/@type = 'institution') then ('
                L.circleMarker([' || replace($place/coord, ' ', ', ') ||"], styleinstitution).bindPopup('"||'<a target="_blank" href="' || $place/id|| '">' || $place/name ||'</a> <br><b>Check in:</b> <a href="http://pleiades.stoa.org/search?SearchableText='||$place/name || '" target="_blank">Pleiades</a>; <a href="https://en.wikipedia.org/wiki/Special:Search/'||$place/name||'" target="_blank">Wikipedia</a>' || (if ($place/mss) then (' </br> Manuscripts here: <ul>' || $mss || '<ul>') else ()) || "')"  || $types
                 || (if ($pos = $count) then '' else ',' ))
                 else ('
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

declare function BetMasMap:RestEntityMap($this, $collection){
let $document := $this
let $id := string($this/@xml:id)
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

   
     <place>
     <id>{$id}</id>
     {for $t in tokenize($document//t:place/@type,  ' ')
     return
     <type type="{$t}"/>}
     {for $t in tokenize($document//t:place/@subtype,  ' ')
     return
     <type type="{$t}"/>}
     <name>{replace(titles:printTitleID($id), "'", '´')}</name>
     <coord>{coord:getCoords($id)}</coord>
     {if ($document//t:height) then <alt>{$document//t:height/text()}</alt> else()}
     </place>

    
    let $style := <style>
    var colPoint1 = '#000';
			var colPoint2 = 'green';
			var style = {{ color: colPoint1, fillColor: colPoint2, radius: 8, opacity: 0.5, fillOpacity: 0.5 }};
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
                for $type in distinct-values($data//type/@type)
                return 
                ('var ' || $type || '= new L.LayerGroup(); 
                ' )
                }
                </layers>
                <style>{$style}</style>
    <data>
    {for $place at $pos in $data
                let $types :=  
                <type>{for $t in $place//type return <i>{('.addTo(' ||data($t/@type) || ')')}</i>}</type>
                let $mss := <mss>{for $ms in $place//mss order by $ms return <m>{('<li><a  target="_blank" href="' || $ms|| '">' || $ms ||'</a></li> ')}</m>}</mss>
               
    return
                ('
                L.circleMarker([' || replace($place/coord, ' ', ', ') ||"], style).bindPopup('"||'<a target="_blank" href="' || $place/id|| '">' || $place/name ||'</a> <br><b>Check in:</b> <a href="http://pleiades.stoa.org/search?SearchableText='||$place/name || '" target="_blank">Pleiades</a>; <a href="https://en.wikipedia.org/wiki/Special:Search/'||$place/name||'" target="_blank">Wikipedia</a>' || (if ($place/mss) then (' </br> Manuscripts here: <ul>' || $mss || '<ul>') else ()) || "')"  || $types
                 || (if ($pos = count($data)) then '' else ',' ))
    

    }
    </data>
    <base>{$basemap}</base>
    <overlay> 
  {let $types :=  
                <type>{for $t in distinct-values($data//type/@type) return <i>{' '|| (data($t)||',')}</i>}</type>
     let $overlays := <over>{for $t in distinct-values($data//type/@type) return <i>{('
     "' ||upper-case(data($t))||'": ' || data($t)||',')}</i>}</over>
     
     return       
    "
        var map = L.map('map', {
		center: ["||$data/coord||"],
		zoom: 6,
		layers: [outdoor, " || replace($types,',$','') || " ],
        fullscreenControl: true,
        // OR 
        fullscreenControl: {
        pseudoFullscreen: false // if true, fullscreen to page width and height
        }
	});


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
