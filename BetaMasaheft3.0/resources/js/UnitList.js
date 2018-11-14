
$(document).on('ready', function () {
    var type = $('#result').data('value')
    var apicall = '/api/SPARQL/SdCunits/' + type 
    $.getJSON(apicall, function (data) {
       $('#result').append('<div class="alert alert-info">There are '+data.total+' Uni'+type+'</div>')
       console.log(data)
       var rs = data.results
         console.log(rs)
        $(rs).each(function(i){
         var unit = this
         console.log(unit)
            $('#result').append('<div class="row"><a target="_blank" href="'+unit+'"> '+unit+' </a></div>')
        });
    });
    });