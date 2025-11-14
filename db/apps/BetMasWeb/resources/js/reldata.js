$("#BetMasRelView").each(function () {
    // Check if vis library is available before using it
    if (typeof vis === 'undefined') {
        console.warn('vis library is not loaded. Skipping relation visualization.');
        return;
    }
    
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