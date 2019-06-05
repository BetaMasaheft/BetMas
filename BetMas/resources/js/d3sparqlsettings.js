
function exec() {
/*    console.log('running sparql query')*/
    var endpoint = d3.select("#endpoint").property("value")
    var sparql = d3.select("#sparql").property("value")
/*    console.log(endpoint)*/
/*    console.log(sparql)*/
var sparql = sparql.replace(/^\s+/g, '')
    if (sparql.startsWith("SELECT")) {
        
        /* Uncomment to see debug information in console */
        d3sparql.debug = true
/*        d3sparql.query(endpoint, sparql, renderforce)*/
        d3sparql.query(endpoint, sparql, rendertable)
    } else {
        // Alternative is to start with CONSTRUCT
        var url, query, jsonUri;
        query = 'https://betamasaheft.eu/'
        var width = 1040,
        height = 700;
        
        var nodeTypes =[ "uri", "center", "bnode", "literal", "property", "type"];
        
        var color = d3.scale.ordinal().domain(nodeTypes).range(colorbrewer.Accent[8]);
        
        var force = d3.layout.force().charge(-100).linkDistance(50).size([width, height]);
        
        var svg = d3.select("div#result").append("svg").attr("width", width).attr("height", height);
        
        var makeId = function (name) {
            var id = "id" + name.replace(/\W/g, "");
            return id;
        }
        jsonUri = endpoint + '?query=' + sparql
        var xhr = d3.xhr(jsonUri);
        xhr.header("Accept", "application/rdf+json");
        xhr. get (function (error, request) {
            // Get a JSON RDF representation, and transform it into a list of graph nodes and links
            var json = JSON.parse(request.responseText);
            var k = Object.keys(json);
            var nodes = {
            };
            //add the query node:
            nodes[query] = {
                type: "center", links: {
                }
            };
            if (json[query]) {
                var l = Object.keys(json[query]);
                for (var h = 0; h < l.length; h++) {
                    var property = l[h] + "|x," + h;
                    nodes[property] = {
                    };
                    nodes[property].type = "property";
                    nodes[property].links = {
                    };
                    if (nodes[query].links[property]) {
                        nodes[query].links[property] += 1;
                    } else {
                        nodes[query].links[property] = 1;
                    }
                    var m = json[query][l[h]];
                    for (var g = 0; g < m.length; g++) {
                        if (! nodes[m[g].value]) {
                            nodes[m[g].value] = {
                            };
                            nodes[m[g].value].links = {
                            };
                            if (m[g].value == query) {
                                nodes[m[g].value].type = "center";
                            } else if (l[h] == "http://www.w3.org/1999/02/22-rdf-syntax-ns#type") {
                                nodes[m[g].value].type = "type";
                            } else {
                                nodes[m[g].value].type = m[g].type;
                            }
                        }
                        if (nodes[property].links[m[g].value]) {
                            nodes[property].links[m[g].value] += 1;
                        } else {
                            nodes[property].links[m[g].value] = 1;
                        }
                    }
                }
            }
            for (var i = 0; i < k.length; i++) {
                if (! nodes[k[i]]) {
                    nodes[k[i]] = {
                    };
                    nodes[k[i]].type = k[i].substring(0, 1) == "_" ? "bnode": "uri";
                    nodes[k[i]].links = {
                    };
                }
                var l = Object.keys(json[k[i]]);
                for (var h = 0; h < l.length; h++) {
                    if (k[i] != query) {
                        if (json[k[i]][l[h]].length == 1) {
                            property = l[h] + "|" + json[k[i]][l[h]][0].value;
                        } else {
                            property = l[h] + "|" + i + "," + h;
                        }
                        nodes[property] = {
                        };
                        nodes[property].type = "property";
                        nodes[property].links = {
                        };
                        if (nodes[k[i]].links[property]) {
                            nodes[k[i]].links[property] += 1;
                        } else {
                            nodes[k[i]].links[property] = 1;
                        }
                        var m = json[k[i]][l[h]];
                        for (var g = 0; g < m.length; g++) {
                            if (! nodes[m[g].value]) {
                                nodes[m[g].value] = {
                                };
                                nodes[m[g].value].links = {
                                };
                                if (m[g].value == query) {
                                    nodes[m[g].value].type = "center";
                                } else if (l[h] == "http://www.w3.org/1999/02/22-rdf-syntax-ns#type") {
                                    nodes[m[g].value].type = "type";
                                } else {
                                    nodes[m[g].value].type = m[g].type;
                                }
                            }
                            if (nodes[property].links[m[g].value]) {
                                nodes[property].links[m[g].value] += 1;
                            } else {
                                nodes[property].links[m[g].value] = 1;
                            }
                        }
                    }
                }
            }
            //console.log(nodes)
            var graphNodes =[];
            var links =[];
            var gNodeList = Object.keys(nodes);
            for (var i = 0; i < gNodeList.length; i++) {
                graphNodes[i] = {
                    "name": gNodeList[i], "group": nodeTypes.indexOf(nodes[gNodeList[i]].type)
                };
                if (graphNodes[i].name == query) {
                    graphNodes[i].weight = 1000;
                }
                var ln = Object.keys(nodes[gNodeList[i]].links);
                for (var j = 0; j < ln.length; j++) {
                    links.push({
                        "source": i, "target": gNodeList.indexOf(ln[j]), "value": nodes[gNodeList[i]].links[ln[j]]
                    });
                }
            }

            // Now, build the graph:
            force.nodes(graphNodes).links(links).start();
            
            svg.append("svg:defs").selectAll("marker").data([ "end"]) // Different link/path types can be defined here
            .enter().append("svg:marker") // This section adds in the arrows
            .attr("id", String).attr("viewBox", "0 -5 10 10").attr("refX", 30).attr("refY", 0).attr("markerWidth", 6).attr("markerHeight", 6).attr("orient", "auto").append("svg:path").attr("d", "M-5,-5L10,0L0,5");
            
            
            var link = svg.selectAll(".link").data(links).enter().append("line").attr("class", function (d) {
                return "link " + makeId(d.source.name) + " " + makeId(d.target.name)
            }).attr("marker-end", "url(#end)").style("stroke-width", function (d) {
                return Math.sqrt(d.value);
            });
            
            var node = svg.selectAll(".node").data(graphNodes).enter().append("g").each(function (d, i) {
                var g = d3.select(this);
                g.attr("id", function (d) {
                    return makeId(d.name)
                });
                var c;
                if (nodeTypes[d.group] == "uri") {
                    c = g.append("a").attr("xlink:href", + encodeURIComponent(d.name)).append("circle");
                } else {
                    c = g.append("circle");
                }
                c.attr("class", function (d) {
                    return "node " + makeId(d.name)
                });
                
                
                if (nodeTypes[d.group] == "center") {
                    c.attr("r", 12);
                } else {
                    c.attr("r", 6);
                }
                c.style("fill", function (d) {
                    return color(d.group);
                });
                g.call(force.drag);
            });
            
            node.append("rect").attr("class", "labelbg").attr("x", 10).attr("y", "-.55em").attr("rx", 3).attr("ry", 3);
            
            node.append("foreignObject").attr("class", "label").attr("dx", 18).attr("dy", ".45em").attr("width", "20em").attr("height", "200px").append("xhtml:html").append("body").append("span").attr("style", "text-align:left;").each(function (d, i) {
                var span = d3.select(this);
                var name = d.name.replace(/\|.+$/, '')
                if ((nodeTypes[d.group] == "uri" || nodeTypes[d.group] == "center") && d.name.match(/^http/)) {
                    span.append("a").attr("href", name).attr("target", "_blank").text(d.name);
                } else if (nodeTypes[d.group] == "bnode") {
                    span.text("_bnode");
                } else {
                    span.text(name);
                }
            });
            
            
            node.on("mouseover", mouseover);
            node.on("mouseout", mouseout);
            
            force.on("tick", function () {
                link.attr("x1", function (d) {
                    return d.source.x;
                }).attr("y1", function (d) {
                    return d.source.y;
                }).attr("x2", function (d) {
                    return d.target.x;
                }).attr("y2", function (d) {
                    return d.target.y;
                });
                node.attr("transform", function (d) {
                    return "translate(" + d.x + "," + d.y + ")"
                });
            });
            
            
            svg.append("svg:g").attr("width", 100).attr("height", 30).append("text").attr("class", "title").attr("x", 20).attr("y", 20).text("Graph for " + query);
        });
        
        var mouseover = function () {
            var g = d3.select(this);
            var t = d3.select(g.node().lastElementChild);
            t.attr("class", "showlabel");
            var n = g.node();
            var parent = n.parentNode;
            parent.removeChild(n);
            parent.appendChild(n);
            d3.selectAll("." + g.attr("id")).classed("highlight", true);
        }
        
        var mouseout = function () {
            var g = d3.select(this);
            d3.select(g.node().lastElementChild).attr("class", "label");
            d3.selectAll("." + g.attr("id")).classed("highlight", false);
        }
    }
}
function renderforce(json) {
    
    var config = {
        "charge": -500,
        "distance": 50,
        "width": 1500,
        "height": 750,
        "selector": "#result"
    }
    d3sparql.forcegraph(json, config)
}

function rendertable(json) {
var config = {
        "selector": "#resulttable"
    }
    d3sparql.htmltable(json, config)
}