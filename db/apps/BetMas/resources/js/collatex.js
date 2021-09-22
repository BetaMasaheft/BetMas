$(document).on({
    ajaxStart: function () {
        $("img#loading").show();
    },
    ajaxStop: function () {
        $("img#loading").hide();
    }
});

$('#addDTS').click(function(){
    
    var input = '<input type="text" class="dts w3-input w3-margin w3-border" placeholder="urn:dts:betmasMS:{manuscriptid}:{passage}-{passage}"></input>'
    $('#dtsURNs').append(input)
});


$('#collate').click(function(){
    var nU =[]
    var dts =[]
$('input.dts').each(function(){
    var value = $( this ).val()
    var dtsuri = 'https://betamasaheft.eu/'+value
    dts.push(dtsuri)
});
$('input.narrUnit').each(function(){
    var value = $( this ).val()
    nU.push(value)
});
console.log(dts)
 

/*should also call dts directly to display passage which is being collated and created divs with that content beside the collation*/

var apicall = '/api/collatex?format=json&dts=' + dts.join(',') + '&nU=' + nU.join(',')
/*console.log('collating@!')*/
var container = $('#collationResult')

/*YUI().use("node", "collatex", function(Y) {
    new Y.CollateX({ serviceUrl: "https://collatex.net/demo/collate" }).toTable([{
        id: "A",
        content: "Hello World"
    }, {
        id: "B",
        tokens: [
            { "t": "Hallo", "n": "hello" },
            { "t": "Welt", "n": "world" }
        ]
    }], Y.one("#collationResult"));
});
*/
$.getJSON(apicall, function( data ) {
console.log(data)
var tablecontainer =  $('<div class="w3-responsive">')
var table = $('<table class="w3-table w3-hoverable"/>')
var head = $('<thead></thead>')
var tr = $('<tr/>')
var body = $('<tbody/>')
var styleperc = 100 / data.witnesses.length 
var style = 'style="width:' + styleperc + '%;"'

$(data.witnesses).each(function(witnesindex){

var th = $('<th class=" w3-padding" '+style+ '>'+this+' [ <a href="/manuscripts/'+this+'/text">text</a>][<a href="/manuscripts/'+this+'/viewer">viewer</a>]</th>')
tr.append(th)
head.append(tr)
});

$(data.table).each(function(){
    //console.log($.isArray(this))
    var arr=[]
    var tr = $('<tr/>')
    $(this).each(function(){
         var tokens = this
    var string = tokens.join(' ')
        var td = $('<td class="w3-padding" '+style+ '>'+string+'</td>')
        tr.append(td)
        arr.push(td.text())
    });
   
 console.log(!!arr.reduce(function(a, b){ return (a === b) ? a : NaN; }))
   if(!!arr.reduce(function(a, b){ return (a === b) ? a : NaN; })){console.log('invariant') , tr.addClass('invariant')}
        
   body.append(tr)
    });

table.append(head)
table.append(body)
tablecontainer.append(table)
container.append(tablecontainer)

});

});

 