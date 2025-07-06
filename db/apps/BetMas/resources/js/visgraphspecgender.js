    var apicall = '/gender/rels'
 //console.log(apicall)
    
    $.getJSON(apicall, function (data) {
    console.log(data)
 var nodes = new vis.DataSet(data.nodes);
var edges = new vis.DataSet(data.edges);
        
var hier = false;
var edgedrag = false;

var clusterIndex = 0;
    var clusters = [];
    var lastClusterZoomLevel = 0;
    var clusterFactor = 0.9;
    var network = null;

var container = document.getElementById('BetMasRelView');

var data = {
    nodes: nodes,
    edges: edges
};
  console.log(data)
var options = {
    layout: {
        improvedLayout: false,
        hierarchical: hier
    },
    edges: {
    
    color:{inherit:true},
        width: 0.15,
        smooth: {
            enabled: false,
            type: "horizontal"
        },
          arrows: {to : true }
    },
    nodes: {
            font: {
                size: 15,
                color: 'rgb(0, 0, 0)'
            }
        },
    
    groups: {
        
        institutions: {
            color: {
                background : 'rgb(255, 210, 77)' 
            }
        },
        
        
        places: {
            color: {
                background: 'rgb(0, 204, 0)'
            }
        },
        
        persons: {
            color: {
                background: 'rgb(230, 77, 0)'}
        },
        
        narratives: {
            color: 'rgb(128, 128, 255)'
        },
        
        works: {
            color: 'rgb(77, 166, 255)'
        },
        
        manuscripts: {
            color: 'rgba(97,195,238,0.5)'
        }
    },
    physics: {
            adaptiveTimestep:false, 
            stabilization: {
                        enabled:true,
                        iterations:2000
                    },
           barnesHut: {
          gravitationalConstant: -8000,
          springConstant: 0.001,
          springLength: 40
         
        }
    },
        interaction: {
          hideEdgesOnDrag: edgedrag,
          tooltipDelay: 200
}
};



var network = new vis.Network(container, data, options);

  console.log(network)
network.on( 'click', function(properties) {
    window.open('/' + properties.nodes, '_blank');
});

// set the first initial zoom level
    network.once('initRedraw', function() {
        if (lastClusterZoomLevel === 0) {
            lastClusterZoomLevel = network.getScale();
        }
    });

    // we use the zoom event for our clustering
    network.on('zoom', function (params) {
        if (params.direction == '-') {
            if (params.scale < lastClusterZoomLevel*clusterFactor) {
                makeClusters(params.scale);
                lastClusterZoomLevel = params.scale;
            }
        }
        else {
            openClusters(params.scale);
        }
    });

    // if we click on a node, we want to open it up!
    network.on("selectNode", function (params) {
        if (params.nodes.length == 1) {
            if (network.isCluster(params.nodes[0]) == true) {
                network.openCluster(params.nodes[0])
            }
        }
    });
    
    $('#clusterOutliers').click( function () {
      network.setData(data);
      network.clusterOutliers();
  });
  
 $('#clusterByHubsize').click( function ()  {
      network.setData(data);
      var clusterOptionsByData = {
          processProperties: function(clusterOptions, childNodes) {
            clusterOptions.label = "[" + childNodes.length + "]";
            return clusterOptions;
          },
          clusterNodeProperties: {borderWidth:3, shape:'box', font:{size:30}}
      };
      network.clusterByHubsize(undefined, clusterOptionsByData);
  });
    
    });


    // make the clusters
    function makeClusters(scale) {
        var clusterOptionsByData = {
            processProperties: function (clusterOptions, childNodes) {
                clusterIndex = clusterIndex + 1;
                var childrenCount = 0;
                for (var i = 0; i < childNodes.length; i++) {
                    childrenCount += childNodes[i].childrenCount || 1;
                }
                clusterOptions.childrenCount = childrenCount;
                clusterOptions.label = childrenCount + " nodes";
                clusterOptions.font = {size: childrenCount*5+30}
                clusterOptions.id = 'cluster:' + clusterIndex;
                clusters.push({id:'cluster:' + clusterIndex, scale:scale});
                return clusterOptions;
            },
            clusterNodeProperties: {borderWidth: 3, shape: 'circle', font: {size: 15}}
        }
        network.clusterOutliers(clusterOptionsByData);
        if (document.getElementById('stabilizeCheckbox').checked === true) {
            // since we use the scale as a unique identifier, we do NOT want to fit after the stabilization
            network.setOptions({physics:{stabilization:{fit: false}}});
            network.stabilize();
        }
    }

    // open them back up!
    function openClusters(scale) {
        var newClusters = [];
        var declustered = false;
        for (var i = 0; i < clusters.length; i++) {
            if (clusters[i].scale < scale) {
                network.openCluster(clusters[i].id);
                lastClusterZoomLevel = scale;
                declustered = true;
            }
            else {
                newClusters.push(clusters[i])
            }
        }
        clusters = newClusters;
        if (declustered === true && document.getElementById('stabilizeCheckbox').checked === true) {
            // since we use the scale as a unique identifier, we do NOT want to fit after the stabilization
            network.setOptions({physics:{stabilization:{fit: false}}});
            network.stabilize();
        }
    }
  
  
  
 