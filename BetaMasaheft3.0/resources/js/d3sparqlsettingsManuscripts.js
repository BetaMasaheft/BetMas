$(document).on('ready', function () {
    var id = $("#graph").data("id") 
    var SdCquery = "SELECT DISTINCT  ?resourceName ?relName ?partName \
    WHERE { \
    BIND('" + id + "' as ?id) \
    ?resource ?rel ?part . \
    BIND(STR(?resource) AS ?r) \
    BIND(STR(?part) AS ?p) \
    BIND(STR(?rel) AS ?strel) \
    FILTER(contains(?r, ?id)) \
    FILTER( ?rel = skos:exactMatch || contains(?strel, 'Synthax')) \
    BIND(IF(contains(?p, 'betamasaheft'), strafter(?p, 'http://betamasaheft.eu/'), strafter(?p, '#')) as ?uri) \
    BIND(replace(?uri , '/', ' ') AS ?partName) \
    BIND(IF(contains(?r, 'betamasaheft'), strafter(?r, 'http://betamasaheft.eu/'), strafter(?r, '#')) as ?ruri) \
    BIND(replace(?ruri , '/', ' ') AS ?resourceName) \
    BIND(IF(contains(?strel, 'betamasaheft'), strafter(?strel, 'http://betamasaheft.eu/'), strafter(?strel, '#')) as ?reluri) \
    BIND(replace(?reluri , '/', ' ') AS ?relName)}"
    $("#graphloadingstatus").text('building the structural graph')
    apicall = "/api/SPARQL/json?query=" + encodeURIComponent(SdCquery)
    $.getJSON(apicall, function (data) {
        
        //console.log(data)
        var SPARQLnodes =[]
        var SPARQLedges =[]
        var ids =[]
        var results = data.results.bindings
        var reslength = results.length
        
        for (var i = 0; i < reslength; i++) {
            var unit = results[i]
            var Rid = unit.resourceName.value
            var Pid = unit.partName.value
            if ($.inArray(Rid, ids) === -1) {ids.push(Rid)
                
            } //else (console.log(Rid + ' is already a listed id'))
            if ($.inArray(Pid, ids) === -1) {
                ids.push(Pid)
            } //else (console.log(Pid + ' is already a listed id'))
            
            var edge = new makeedge(Rid.replace('\s', '_'), unit.relName.value, Pid.replace('\s', '_'))
            SPARQLedges.push(edge)
          
        }
         // console.log(ids)
        for (var i = 0; i < ids.length; i++) {
        var id = ids[i]
            var node = new makenode(id)
            SPARQLnodes.push(node)
        }
        
        function makenode(unit) {
            this.label = unit
            this.id = unit.replace('\s', '_')
        }
        
        function makeedge(idfrom, relname, idto) {
            this. from = idfrom
            this.label = relname
            this.to = idto
        }
        //console.log(SPARQLnodes)
        //console.log(SPARQLedges)
        var nodes = new vis.DataSet(SPARQLnodes);
        var edges = new vis.DataSet(SPARQLedges);
        var hier = false;
        var edgedrag = false;
        var container = document.getElementById('SdCGraph');
        
        var data = {
            nodes: nodes,
            edges: edges
        };
        
        var options = {
            layout: {
                improvedLayout: false,
                hierarchical: hier
            },
            edges: {
                
                color: {
                    inherit: true
                },
                width: 0.15,
                smooth: {
                    enabled: false,
                    type: "horizontal"
                },
                arrows: {
                    to: true
                }
            },
            nodes: {
                font: {
                    size: 15,
                    color: 'rgb(0, 0, 0)'
                }
            },
            
            physics: {
                adaptiveTimestep: false,
                stabilization: {
                    enabled: true,
                    iterations: 2000
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
        
        
         if(ids.length >= 1){container.style.height = '600px'} // only give an height to the box if there is a graph, i.e. if there are ids to make nodes
  
        var network = new vis.Network(container, data, options);
         });
    
    
    
    // in this attribute is stored a full api query line to the rdf needed in json. it will call a function which gets the rdf file as it is stored and transform it to json. no query is made for this.
    
    $("#graphloadingstatus").text('building the general graph representation')
    var rdf = "SELECT DISTINCT  ?resourceName ?partName \
    WHERE { \
    BIND('" + id + "' as ?id) \
    ?resource ?rel ?part . \
    BIND(STR(?resource) AS ?r) \
    BIND(STR(?part) AS ?p) \
    BIND(STR(?rel) AS ?strel) \
    FILTER(!contains(?r, 'msitem')) \
    FILTER(!contains(?p, 'msitem')) \
    FILTER(contains(?r, ?id)) \
    FILTER(?rel = dcterms:hasPart ||?rel = skos:exactMatch || contains(?strel, 'Synthax') || ?rel = rdf:type) \
    BIND(IF(contains(?p, 'betamasaheft'), strafter(?p, 'http://betamasaheft.eu/'), strafter(?p, 'http://Syntaxe.du.Codex/ontology#')) as ?uri) \
    BIND(replace(?uri , '/', ' ') AS ?partName) \
    BIND(IF(contains(?r, 'betamasaheft'), strafter(?r, 'http://betamasaheft.eu/'), strafter(?r, 'http://Syntaxe.du.Codex/ontology#')) as ?ruri) \
    BIND(replace(?ruri , '/', ' ') AS ?resourceName)} LIMIT 250"
    var endpoint = '/api/SPARQL/json'
    d3sparql.query(endpoint, rdf, renderforce)
    function renderforce(json) {
        
        var config = {
            "charge": -300,
            "distance": 70,
            "width": 1000,
            "height": 750,
            "selector": "#GraphResult"
        }
        d3sparql.forcegraph(json, config)
    }
});