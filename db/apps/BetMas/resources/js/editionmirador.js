

$(function () {
    var apicall = data[ "0"].collectionUri
/*    the data variable is defined in the page and calculated from the XSLT transformation
 * e.g. var data = [{collectionUri: "/api/iiif/witnesses/LIT2170Peripl"}]
 *  */
/* request data from the URI in data, the iiif.xql RESTXQ function returns a collection with all manuscripts which are listed in witnesses*/
    $.getJSON(apicall, function (coldata) {
/*    initialize the arrays of manifests and window objects*/
         var loadings =[]
        var manifests =[]
        
/*        loop each of the manifests in the collection*/
        $(coldata.manifests).each(function (i) {
        
/*        for each manifest add an object */
            var manifest = {
                manifestUri: this[ '@id'],
                location: this[ 'label']
            }
            manifests.push(manifest)
            
/*            this expects both the information about the witness and those about the pb to be declared explicitely in the html page and ensures that for each pb the correct manuscript start canvas and manifest are taken.*/
            var startcanvas = $('span[class="imageLink"][data-manifest="' + this[ '@id'] + '"]').data('canvas')
            
/*           for each loading add an object to windowObject */
            var loading = {
                loadedManifest: this[ '@id'],
                canvasID: startcanvas,
                viewType: "ImageView"
            }
/*            if there are more then one manifest, they will be displayed one beside the other, in a row (up to 5)*/
            if(coldata.manifests.length > 1){loading['slotAddress'] = "row1.column"+(i+1)}
            
            loadings.push(loading)
        });
        var mirador = {
        id: "viewer",
        data: manifests,
        windowObjects: loadings
    }
    
/*            if there are more then one manifest, they will be displayed one beside the other, in a row (up to 5) so the layout property needs to be specified. (up to 1 row of 5)*/
    if(manifests.length > 1){mirador['layout'] = "1x"+manifests.length}
    
    console.log(mirador)
        Mirador(mirador)
    });
    
   
});
