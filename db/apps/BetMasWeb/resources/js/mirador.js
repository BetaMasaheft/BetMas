$(function() {
        Mirador({
          id: "viewer",
          data: data,  
  windowObjects: [{ 
  loadedManifest: loadedM,
  canvasID: canvasid,
  viewType: "ImageView"
  }]
        });
      });

/*https://stackoverflow.com/questions/33092386/how-to-determine-if-a-bootstrap-collapse-is-opening-or-closing

* Plus Hugh Cayless answer from IIIF-discuss list*/

document.addEventListener("contextmenu", function(e){
    e.preventDefault();
}, false);