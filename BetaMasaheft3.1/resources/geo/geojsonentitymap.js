var mbAttr = 'Map data © OpenStreetMap contributors, ' +
			'CC-BY-SA, ' +
			'Imagery © Mapbox',
		mbUrl = 'https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoicGlldHJvbGl1enpvIiwiYSI6ImNpbDB6MjE0bDAwOGl4MW0wa2JvMDd0cHMifQ.wuV3-VuvmCzY69kWRf6CHA';
                                     
	var grayscale   = L.tileLayer(mbUrl, {id: 'mapbox.light', attribution: mbAttr}),
		streets  = L.tileLayer(mbUrl, {id: 'mapbox.streets',   attribution: mbAttr});
		satellite = L.tileLayer(mbUrl, {id: 'mapbox.satellite',   attribution: mbAttr});
		outdoor = L.tileLayer(mbUrl, {id: 'mapbox.outdoors',   attribution: mbAttr});
            
    var colPoint1 = '#000';
			var colPoint2 = 'green';
			var style = { color: colPoint1, fillColor: colPoint2, radius: 8, opacity: 0.5, fillOpacity: 0.5 };
   
   
   
   var baseLayers = {
		"Altitude": outdoor,
		"Grayscale": grayscale,
		"Satellite": satellite,
		"Streets": streets
	};
	

var apicall = "/"+placeid+".json";
var geojsonLayer = new L.GeoJSON.AJAX(apicall);
			  
        var map = L.map('entitymap', {
		center: [10.8953849, 37.9227273],
		zoom: 6,
		layers: [outdoor, geojsonLayer],
        fullscreenControl: true,
        // OR 
        fullscreenControl: {
        pseudoFullscreen: false // if true, fullscreen to page width and height
        }
	});

var overlays = {
    "this place": geojsonLayer
};
      
                L.control.layers(baseLayers, overlays).addTo(map);
/*https://stackoverflow.com/questions/29735989/leaflet-ajax-map-fitbounds*/
geojsonLayer.on('data:loaded', function() {
  map.fitBounds(geojsonLayer.getBounds());
}.bind(this));
                