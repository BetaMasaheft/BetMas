var colPoint = '#000';
var colPlace = 'rgb(172, 230, 0)';
var colIns = 'rgb(255, 212, 128)';
var mbAttr = 'Map data © OpenStreetMap contributors, ' + 'CC-BY-SA, ' + 'Imagery © Mapbox';
var mbUrl = 'https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoicGlldHJvbGl1enpvIiwiYSI6ImNpbDB6MjE0bDAwOGl4MW0wa2JvMDd0cHMifQ.wuV3-VuvmCzY69kWRf6CHA';
var grayscale = L.tileLayer(mbUrl, {
    id: 'mapbox.light', attribution: mbAttr
});
var streets = L.tileLayer(mbUrl, {
    id: 'mapbox.streets', attribution: mbAttr
});
var satellite = L.tileLayer(mbUrl, {
    id: 'mapbox.satellite', attribution: mbAttr
});
var outdoor = L.tileLayer(mbUrl, {
    id: 'mapbox.outdoors', attribution: mbAttr
});


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
var searchCtrl = L.control.fuseSearch(options);
var tobeindexed = ['title']
searchCtrl.addTo(map);
searchCtrl.indexFeatures(institutions, tobeindexed);	
L.control.layers(baseLayers, overlays).addTo(map);




