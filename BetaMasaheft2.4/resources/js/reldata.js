$("#BetMasRelView").each(function () {
    var entity = $("#BetMasRelView").data('value');
    console.log(entity)
    
    var apiurl = '/api/relations/'
    
    var apicall = apiurl + entity
    console.log(apicall)
    var nodes;
    var edges;
    $.getJSON(apicall, function (data) {
       // console.log(apicall)
        console.log(data)
        nodes = new vis.DataSet(data.nodes);
edges = new vis.DataSet(data.edges);
        var options = {
            layout: {
                randomSeed: entity
            }
        }
        console.log(edges)
    });
});

$(document).on({
    ajaxStart: function() { $("img#loading").show();   },
     ajaxStop: function() {  $("img#loading").hide(); }    
});