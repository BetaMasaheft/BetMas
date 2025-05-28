
$(document).on('ready', function () {
    var id = $("#Chojnacki").data("id")
    var restcall = '/api/Chojnacki/' + id
    $.getJSON(restcall, function (data) {
        // check the data for images
        //console.log(data)
        if (data.total >= 1) {
            // if there is one, then make the box and tell how many there are in total
            $("#Chojnacki").append('<h3>' + data.total + ' related items from <a href="https://digi.vatlib.it/stp/Chojnacki" target="_blank">Chojnacki Archive at the Vatican Library</a></h3>')
            // for each of the record obtained from the xquery called above, call the iiif manifest
            $(data.ChojnackItems).each(function (Choj) {
                var record = this
                // the manifest url
                var manifest = 'https://digi.vatlib.it/iiif/STP_' + encodeURIComponent(record.segnatura) + '/manifest.json'
                // get the manifest
                $.getJSON(manifest, function (man) {
                    
                    
             
                    //print the name of the record in the digivatlib, which includes the placeholder for the viewer
                    var relatedItem = '<p class="w3-padding"><a target="_blank" href="' + record.link + '">' + record.name + '</a>, \
                    (<a target="_blank" href="https://digi.vatlib.it/view/STP_' + record.segnatura + '">' + record.segnatura + '</a>)</p>\
                    <div id="choj' + record.digvatID + '"/>'
             
                    
                    //prepare a variable for the tiles
                    var tiles =[]
                    var manif = man
                    //console.log(manif.sequences["0"].canvases)
                    
                    var canvass = manif.sequences[ "0"].canvases
                    
                    // for each canvas in the manifest make a tilesource as required by OSD
                    $(canvass).each(function (i) {
                        // console.log(this)
                        
                        onj = {
                            "@context": "http://iiif.io/api/image/2/context.json",
                            "@id": this.images[ "0"].resource.service[ "@id"],
                            "profile": "http://iiif.io/api/image/2/level2.json",
                            "width": this.width, "height": this.height,
                            "protocol": "http://iiif.io/api/image",
                            "tiles":[ {
                                "scaleFactors":[1, 2, 4, 8, 16, 32],
                                "width": 1024
                            }]
                        }
                        //console.log(onj)
                        tiles.push(onj)
                    });
                    
                    
                    
                    //                  produce the OSD script with the id of the container and the tiles from the manifest
                    var opensea = '<script> \
                    OpenSeadragon({\
                    id:                 "choj' + record.digvatID + '",\
                    prefixUrl:          "../resources/openseadragon/images/",\
                    preserveViewport:   true,\
                    visibilityRatio:    1,\
                    minZoomLevel:       1,\
                    defaultZoomLevel:   1,\
                    sequenceMode:       true, \
                    tileSources : ' + JSON.stringify(tiles) + '\
                    })\
                    </script>'
                    
                    // append to the Chojnacki div the record with one name, one viewer and all the available photos
                    $("#Chojnacki").append('<div  class="w3-container">' + relatedItem + opensea + '</div>')
                });
            });
            
            //  $("#Chojnacki").addClass('w3-container')
        }
    });
});
