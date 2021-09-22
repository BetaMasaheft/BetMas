$(function() {
        Mirador({
          id: "viewer",
          layout : countlayout,
          data: data,  
  windowObjects: windowobjs
        });
      });

/*https://stackoverflow.com/questions/33092386/how-to-determine-if-a-bootstrap-collapse-is-opening-or-closing

* Plus Hugh Cayless answer from IIIF-discuss list*/

document.addEventListener("contextmenu", function(e){
    e.preventDefault();
}, false);