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