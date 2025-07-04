/*change for MAPBOX Classic style
 * L.tileLayer('https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}', {
attribution: '© <a href="https://www.mapbox.com/about/maps/">Mapbox</a> © <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> <strong><a href="https://www.mapbox.com/map-feedback/" target="_blank">Improve this map</a></strong>',
tileSize: 512,
maxZoom: 18,
zoomOffset: -1,
id: 'mapbox/streets-v11',
accessToken: 'YOUR_MAPBOX_ACCESS_TOKEN'
}).addTo(map);
 * */
var mbAttr = '© <a href="https://www.mapbox.com/about/maps/">Mapbox</a> © <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> <strong><a href="https://www.mapbox.com/map-feedback/" target="_blank">Improve this map</a></strong>',
       mbUrl = 'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token=pk.eyJ1IjoicGlldHJvbGl1enpvIiwiYSI6ImNpbDB5cTZlcjAwOWR3OW0wbG5yemJzeGoifQ.-D9ed84-kODSYEb5gpPMRQ',
       mbAT = 'pk.eyJ1IjoicGlldHJvbGl1enpvIiwiYSI6ImNpbDB5cTZlcjAwOWR3OW0wbG5yemJzeGoifQ.-D9ed84-kODSYEb5gpPMRQ'        ;                      
var grayscale   = L.tileLayer(mbUrl, {
	                                           tileSize: 512,
                                                          maxZoom: 18,
                                                          zoomOffset: -1,
                                                          id: 'mapbox/light-v10', 
                                                            attribution: mbAttr,
                                                            accessToken: mbAT}),
          streets  = L.tileLayer(mbUrl, {
	                                           tileSize: 512,
                                                          maxZoom: 18,
                                                          zoomOffset: -1,
                                                          id: 'mapbox/streets-v11',  
                                                          attribution: mbAttr,
                                                            accessToken: mbAT});
		satellite = L.tileLayer(mbUrl, {
	                                           tileSize: 512,
                                                          maxZoom: 18,
                                                          zoomOffset: -1,
                                                          id: 'mapbox/satellite-v9', 
                                                          attribution: mbAttr,
                                                            accessToken: mbAT});
		outdoor = L.tileLayer(mbUrl, {
	                                           tileSize: 512,
                                                          maxZoom: 18,
                                                          zoomOffset: -1,
                                                          id: 'mapbox/outdoors-v11', 
                                                          attribution: mbAttr,
                                                            accessToken: mbAT});
            
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