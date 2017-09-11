$(document).ready(function () {
$("a.reference").on("click", function () {
 var el = this;
var reference = $(this).data('value')
var splitref = reference.split("/");
var sourceReference = $(this).data('ref')
var bmid = $(this).data('bmid')
var apiDTS = '/api/dts/text/'
var result =""

 $.getJSON(apiDTS + reference, function (data) {
 var id = data["0"].id
 var cit = data["0"].citation
 var title = data["0"].title
 var text = data["0"].text
 if(data["0"].info){result+='<p>There is no text yet for this passage in Beta maṣāḥǝft.</p><a target="_blank" href="/works/' + bmid+ '">See Work record</a>'} else {
 result += '<p>Text of ' +cit +' .</p><p>'+text+'</p><a target="_blank" href="/' + bmid+ '/text?start=' + splitref[1]+ '">See full text</a>'}
$(el).popover({
        html: true, 
        content: result, 
        title: 'Text Passage'
    });
})
})

})