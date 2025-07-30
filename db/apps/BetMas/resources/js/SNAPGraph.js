$(document).on('ready', function () {
    var id = $("#graph").data("id") 
    var SNAPquery = " SELECT DISTINCT  ?resourceName ?relName ?partName \
WHERE { \
{?person1 snap:hasBond ?bondName ; \
crm:P48_has_preferred_identifier '" + id + "' . \
?bondName rdf:type ?relName; \
snap:bond-with ?person2 \
BIND(?person1 as ?resourceName) \
BIND(?person2 as ?partName) \
} UNION {  \
?person1 snap:hasBond ?bondwithSubject . \
?bondwithSubject rdf:type ?relwithSubject; \
                       snap:bond-with ?person2 . \
?person2 crm:P48_has_preferred_identifier '" + id + "' . \
?person1 snap:hasBond ?bondName . \
?bondName rdf:type ?relName; \
                       snap:bond-with ?person3 . \
BIND(?person1 as ?resourceName) \
BIND(?person3 as ?partName) \
} UNION { \
?person1 snap:hasBond ?bondName ; \
                   crm:P48_has_preferred_identifier '" + id + "' . \
?bondwithSubject rdf:type ?relwithSubject; \
		snap:bond-with ?person2 . \
?person2 snap:hasBond ?bondName . \
?bondName rdf:type ?relName; \
snap:bond-with ?person3 . \
BIND(?person2 as ?resourceName) \
BIND(?person3 as ?partName) \
} UNION {\
?person1 snap:hasBond ?bondName ; \
crm:P48_has_preferred_identifier '" + id + "' . \
?bondName rdf:type ?relName; \
snap:bond-with ?person2 . \
?person2 snap:hasBond ?bondName . \
?bondName rdf:type ?relName; \
snap:bond-with ?person3 . \
BIND(?person2 as ?resourceName) \
BIND(?person3 as ?partName) \
}UNION { \
?partName bm:wifeOf ?resourceName ; \
crm:P48_has_preferred_identifier '" + id + "' . \
BIND(bm:wifeOf as ?relName) \
}UNION { \
?partName bm:wifeOf ?resourceName . \
?resourceName crm:P48_has_preferred_identifier '" + id + "' . \
BIND(bm:wifeOf as ?relName) \
}UNION { \
?resourceName bm:husbandOf ?partName ; \
crm:P48_has_preferred_identifier '" + id + "' .  \
BIND(bm:husbandOf as ?relName) \
} UNION { \
?partName bm:husbandOf ?resourceName . \
?resourceName crm:P48_has_preferred_identifier '" + id + "' .  \
BIND(bm:husbandOf as ?relName) \
}  }"
     
    $("#graphloadingstatus").text('building the structural graph')
    apicall = "/api/SPARQL/json?query=" + encodeURIComponent(SNAPquery)
    $.getJSON(apicall, function (data) {
        
       console.log(data)
        var SPARQLnodes =[]
        var SPARQLedges =[]
        var ids =[]
        var results = data.results.bindings
        if (results == null){$('#SNAPGraph').text('the sparql query returned no results')} else {
        var reslength = ''
        if(results.length){reslength = results.length} else {reslength = 1}
        
        $(results).each(function(i){
            var unit = this
            var Rid = unit.resourceName.value
            var Pid = unit.partName.value
            if ($.inArray(Rid, ids) === -1) {ids.push(Rid)
                
            } //else (console.log(Rid + ' is already a listed id'))
            if ($.inArray(Pid, ids) === -1) {
                ids.push(Pid)
            } //else (console.log(Pid + ' is already a listed id'))
            
            var edge = new makeedge(Rid.replace(' ', '_'), unit.relName.value, Pid.replace(' ', '_'))
            SPARQLedges.push(edge)
          
        });
        
        
         // console.log(ids)
       $(ids).each(function(i){
        var id = this
            var node = new makenode(id)
            SPARQLnodes.push(node)
        });
        
        function makenode(unit) {
            this.label = unit.replace('https://betamasaheft.eu/', '')
            this.id = unit.replace(' ', '_')
        }
        
        function makeedge(idfrom, relname, idto) {
            this.from = idfrom
            this.label = relname.replace('http://data.snapdrgn.net/ontology/snap#', 'snap:')
            this.to = idto
        }
        //console.log(SPARQLnodes)
        //console.log(SPARQLedges)
        var nodes = new vis.DataSet(SPARQLnodes);
        var edges = new vis.DataSet(SPARQLedges);
        var hier = false;
        var edgedrag = false;
        var container = document.getElementById('SNAPGraph');
        
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
        network.on( 'click', function(properties) {
    window.open(properties.nodes, '_blank');
    });
        }
        
        });
         
           var rdf = "SELECT DISTINCT ?name ?attestation ?citation ?role ?roleType \
WHERE { \
?person a oa:Annotation ; \
oa:hasBody bm:" + id + "; \
lawd:hasAttestation ?attestation ; \
lawd:hasCitation ?citation . \
OPTIONAL{?person lawd:hasName ?name .} \
OPTIONAL{ ?person bm:hasRole ?R . \
?R bm:roleType ?roleType; \
bm:roleName ?role .}}ORDER BY ?person "
                         
    var endpoint = '/api/SPARQL/json'
    
   apicall = endpoint + "?query=" + encodeURIComponent(rdf)
   
    $.getJSON(apicall, function (data) {
        
        //console.log(data)
        var table = $('<table class="table table-responsive"></table>')
        var thead = $('<thead><th>Name</th><th>Citation</th><th>Role</th></thead>')
        var tbody = $('<tbody></tbody>')
        
         var results = data.results.bindings
        //var reslength = results.length
        //console.log(reslength)
        $(results).each(function(i){
        var res = this
        var RandT = ''
        var typ = ''
        if(res['role']){
        RandT += res.role.value
        if(res['roleType']){
        typ = res.roleType.value
        var type = typ.replace('https://betamasaheft.eu/role/','')
        
        RandT+=' (' + type+')'
        }
        }
        var NAME = ''
        if(res['name']){NAME = res.name.value} else {NAME = 'empty tag'}
       var link = res.attestation.value
        var textlink = link.replace('https://betamasaheft.eu/api/dts/document?id=urn:dts:betmas:','/works/')
        var textlink2 = textlink.replace(':', '/text?start=')
        //console.log(textlink2)
        var tr = $('<tr><td>'+NAME+'</td><td><a href="'+textlink2+'">'+res.citation.value+'</a></td><td>'+RandT+ '</td></tr>')
        $(tbody).append(tr)
        });
        
        $(table).append(thead)
        $(table).append(tbody)
        $('#AttestationsInWorks').append(table)
        
        });
    
    });
    
    