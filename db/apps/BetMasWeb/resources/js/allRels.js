var network;

  var allNodes;
  var highlightActive = false;
  var nodesDataset;
  var edgesDataset;
  
  // Check if vis library is available before using it
  if (typeof vis === 'undefined') {
    console.warn('vis library is not loaded. Skipping relation visualization.');
    // Create dummy datasets to prevent errors
    nodesDataset = { get: function() { return {}; }, update: function() {} };
    edgesDataset = { get: function() { return {}; }, update: function() {} };
  } else if (typeof nodes !== 'undefined' && typeof edges !== 'undefined') {
    nodesDataset = new vis.DataSet(nodes); 
    edgesDataset = new vis.DataSet(edges);
  } else {
    // nodes and edges not yet defined, create empty datasets
    nodesDataset = { get: function() { return {}; }, update: function() {} };
    edgesDataset = { get: function() { return {}; }, update: function() {} };
  } 


  function redrawAll() {
    // Check if vis library is available
    if (typeof vis === 'undefined') {
      console.warn('vis library is not loaded. Cannot draw relation visualization.');
      return;
    }
    
    var container = document.getElementById('BetMasRelView');
    if (!container) {
      return;
    }

    var options = {
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
            },
            borderWidth: 2,
            shape: 'ellipse',
            shadow:true, 
            scaling: {
            customScalingFunction: function (min,max,total,value) {
              return value/total;
            },
            min:5,
            max:150
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
        stabilization: false,
        barnesHut: {
          gravitationalConstant: -80000,
          springConstant: 0.001,
          springLength: 200,
          stabilization: {
                        enabled:true,
                        iterations:2000
                    }
        }
      },
      interaction: {
        tooltipDelay: 200,
        hideEdgesOnDrag: true
      }
    };

    var data = {nodes:nodesDataset, edges:edgesDataset};

    network = new vis.Network(container, data, options);
allNodes = nodesDataset.get({returnType:"Object"});

    network.on("click",neighbourhoodHighlight);
/*network.on( 'click', function(properties) {
    window.open('http://betamasaheft.aai.uni-hamburg.de/' + properties.nodes, '_blank');
});
*/
  }

function neighbourhoodHighlight(params) {
    // if something is selected:
    if (params.nodes.length > 0) {
      highlightActive = true;
      var i,j;
      var selectedNode = params.nodes[0];
      var degrees = 2;

      // mark all nodes as hard to read.
      for (var nodeId in allNodes) {
        allNodes[nodeId].color = 'rgba(200,200,200,0.5)';
        if (allNodes[nodeId].hiddenLabel === undefined) {
          allNodes[nodeId].hiddenLabel = allNodes[nodeId].label;
          allNodes[nodeId].label = undefined;
        }
      }
      var connectedNodes = network.getConnectedNodes(selectedNode);
      var allConnectedNodes = [];

      // get the second degree nodes
      for (i = 1; i < degrees; i++) {
        for (j = 0; j < connectedNodes.length; j++) {
          allConnectedNodes = allConnectedNodes.concat(network.getConnectedNodes(connectedNodes[j]));
        }
      }

      // all second degree nodes get a different color and their label back
      for (i = 0; i < allConnectedNodes.length; i++) {
        allNodes[allConnectedNodes[i]].color = 'rgba(150,150,150,0.75)';
        if (allNodes[allConnectedNodes[i]].hiddenLabel !== undefined) {
          allNodes[allConnectedNodes[i]].label = allNodes[allConnectedNodes[i]].hiddenLabel;
          allNodes[allConnectedNodes[i]].hiddenLabel = undefined;
        }
      }

      // all first degree nodes get their own color and their label back
      for (i = 0; i < connectedNodes.length; i++) {
        allNodes[connectedNodes[i]].color = undefined;
        if (allNodes[connectedNodes[i]].hiddenLabel !== undefined) {
          allNodes[connectedNodes[i]].label = allNodes[connectedNodes[i]].hiddenLabel;
          allNodes[connectedNodes[i]].hiddenLabel = undefined;
        }
      }

      // the main node gets its own color and its label back.
      allNodes[selectedNode].color = undefined;
      if (allNodes[selectedNode].hiddenLabel !== undefined) {
        allNodes[selectedNode].label = allNodes[selectedNode].hiddenLabel;
        allNodes[selectedNode].hiddenLabel = undefined;
      }
    }
    else if (highlightActive === true) {
      // reset all nodes
      for (var nodeId in allNodes) {
        allNodes[nodeId].color = undefined;
        if (allNodes[nodeId].hiddenLabel !== undefined) {
          allNodes[nodeId].label = allNodes[nodeId].hiddenLabel;
          allNodes[nodeId].hiddenLabel = undefined;
        }
      }
      highlightActive = false
    }

    // transform the object into an array
    var updateArray = [];
    for (nodeId in allNodes) {
      if (allNodes.hasOwnProperty(nodeId)) {
        updateArray.push(allNodes[nodeId]);
      }
    }
    if (typeof vis !== 'undefined' && nodesDataset && nodesDataset.update) {
      nodesDataset.update(updateArray);
    }
    }
    
  // Only call redrawAll if vis is available
  if (typeof vis !== 'undefined') {
    redrawAll();
  }