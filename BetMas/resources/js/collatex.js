$(document).on({
    ajaxStart: function () {
        $("img#loading").show();
    },
    ajaxStop: function () {
        $("img#loading").hide();
    }
});

$('#addDTS').click(function(){
    
    var input = '<input type="text" class="dts form-control col-md-6" placeholder="urn:dts:betmasMS:{manuscriptid}:{passage}-{passage}"></input>'
    $('#dtsURNs').append(input)
});


$('#collate').click(function(){
    
    var dts =[]
$('input.dts').each(function(){
    var value = $( this ).val()
    dts.push(value)
});
 

/*should also call dts directly to display passage which is being collated and created divs with that content beside the collation*/

var apicall = '/api/collatex?format=json&dts=' + dts.join(',')
var container = $('#collationResult')
$.getJSON(apicall, function( data ) {
//console.log(data)
var table = $('<table class="table table-responsive"/>')
var head = $('<thead><tr></tr></thead>')
var body = $('<thead/>')

$(data.witnesses).each(function(witnesindex){
var th = $('<th>'+this+'</th>')
head.append(th)
});

$(data.table).each(function(){
    //console.log($.isArray(this))
    var arr=[]
    var tr = $('<tr/>')
    $(this).each(function(){
         var tokens = this
    var string = tokens.join(' ')
        var td = $('<td class="col-md-6">'+string+'</td>')
        tr.append(td)
        arr.push(td.text())
    });
   
 console.log(!!arr.reduce(function(a, b){ return (a === b) ? a : NaN; }))
   if(!!arr.reduce(function(a, b){ return (a === b) ? a : NaN; })){console.log('invariant') , tr.addClass('invariant')}
        
   body.append(tr)
    });

table.append(head)
table.append(body)
container.append(table)

});

});

 