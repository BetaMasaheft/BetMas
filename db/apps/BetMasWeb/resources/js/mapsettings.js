 L.mapbox.accessToken = 
        'pk.eyJ1IjoicGlldHJvbGl1enpvIiwiYSI6ImNpbDB5cTZlcjAwOWR3OW0wbG5yemJzeGoifQ.-D9ed84-kODSYEb5gpPMRQ';
        var 
        ancientworld = L.mapbox.tileLayer('isawnyu.map-knmctlkh')
        grayscale   = L.mapbox.styleLayer('mapbox://styles/mapbox/light-v10'),
        streets  = L.mapbox.styleLayer('mapbox://styles/mapbox/streets-v11');
        
        
        var map = L.map('map', 
        {
        center: [11.5500, 39.2833],
        zoom: 5,
        layers: [ancientworld, grayscale, streets],
        fullscreenControl: true,
        // OR
        fullscreenControl: {
        pseudoFullscreen: false // if true, fullscreen to page width and height
        }
        }
        );
        
        
        
        
        
        function onEachFeature(feature, layer) {
        
        var popupContent = "See more information about this " + feature.properties.type + feature.properties.name + ;
        
        
        
        layer.bindPopup(popupContent);
        }