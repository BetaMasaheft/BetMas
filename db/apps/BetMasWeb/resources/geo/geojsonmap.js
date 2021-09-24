var colPoint = '#000';
var colPlace = 'rgb(172, 230, 0)';
var colIns = 'rgb(255, 212, 128)';
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


function onEachFeature(feature, layer) {
    
    var tjoined = ''
    if (feature.place_types) {
        var t = feature.place_types
        if (Array.isArray(t)) {
      //  console.log(t)
            var joined = t.join(", ");
            tjoined += joined
            // console.log(joined)
        } else {
       // console.log('not array?')
        // console.log(t)
            tjoined += t
        }
    };
    
    feature.layer = layer;
    var popupContent = '<p><a target="_blank" href="/' + feature.id + '">' + feature.properties.title + " (" + tjoined + "), " + feature.id + "</a></p>";
    
    if (feature.details) {
        popupContent += feature.details;
    }
    
    layer.bindPopup(popupContent);
    
}

var ins= L.geoJSON(institutions, {
   
    onEachFeature: onEachFeature,
    
    pointToLayer: function (feature, latlng) {
        return L.circleMarker(latlng, {
            
            radius: 10,
            fillColor: colIns,
            color: colPoint,
            opacity: 0.5,
            fillOpacity: 0.5
        });
    }
});

var pla = L.geoJSON(places, {
   
    onEachFeature: onEachFeature,
    
    pointToLayer: function (feature, latlng) {
        return L.circleMarker(latlng, {
            radius: 5,
            fillColor: colPlace,
            color: colPoint,
            opacity: 0.5,
            fillOpacity: 0.7
        });
    }
});



var colPoint1 = '#000';
var colPoint2 = 'green';
var style = {
    color: colPoint1, fillColor: colPoint2, radius: 8, opacity: 0.5, fillOpacity: 0.5
};

var baseLayers = {
    "Altitude": outdoor,
    "Grayscale": grayscale,
    "Satellite": satellite,
    "Streets": streets
};


 

var map = L.map('map', {
    center:[10.5500, 39.2833],
    zoom: 6,
    layers:[outdoor, ins, pla],
    fullscreenControl: true,
    // OR
    fullscreenControl: {
        pseudoFullscreen: false // if true, fullscreen to page width and height
    }
});

var overlays = {
    "Repositories": ins,
    "Places": pla
};

var legend = L.control({
position: 'bottomright'
});

legend.onAdd = function (map) {

var div = L.DomUtil.create('div', 'info legend')

div.innerHTML += '<i style="background: rgb(255, 212, 128)"></i> repositories <br></br> <i style="background: rgb(172, 230, 0)"></i> places'


return div;
};

legend.addTo(map);
 var options = {
        position: 'topright',
        title: 'Search',
        placeholder: 'ex: Aksumite, Gondar, town',
        maxResultLength: 15,
        threshold: 0.5,
        showInvisibleFeatures: true,
        showResultFct: function(feature, container) {
            props = feature.properties;
            var name = L.DomUtil.create('b', null, container);
            name.innerHTML = props.title;

            container.appendChild(L.DomUtil.create('br', null, container));

             var info = props.title;
            container.appendChild(document.createTextNode(info));
        }
    };
/*var searchCtrl = L.control.fuseSearch(options);*/
var tobeindexed = ['title']
/*searchCtrl.addTo(map);
searchCtrl.indexFeatures(institutions, tobeindexed);*/	
L.control.layers(baseLayers, overlays).addTo(map);




