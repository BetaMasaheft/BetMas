
$(document).on('ready', function () {
    var type = $('#result').data('value')
    var apicall = '/api/SPARQL/SdCunits/' + type 
    $.getJSON(apicall, function (data) {
       $('#result').append('<div class="w3-panel w3-card-4 w3-gray">There are '+data.total+' Uni'+type+'</div>')
       console.log(data)
       var rs = data.results
         console.log(rs)
        $(rs).each(function(i){
         var unit = this
         console.log(unit)
            $('#result').append('<div class="w3-row"><a target="_blank" href="'+unit+'"> '+unit+' </a></div>')
        });
    });
    });