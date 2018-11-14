
$('#hypothesisFeed').on('click', function () {
 var input = $(this).data('value')
var url = "https://hypothes.is/api/search?tag=BetMas:" + input + "&limit=200"
console.log(url)

$.ajaxSetup({ cache: true });
$.getJSON( url, function( data ) {
console.log(data)
  var items = [];
       for (var i = 0; i < data.total; i++) {
       var ann = data.rows[i]
       var content = "";
       var contentdata = ann.text
       if(contentdata.startsWith("http")){content += "<a href='"+contentdata +"'>link</a>"} else {content += contentdata};
       var url = "";
       var urldata = ann.uri
       if(urldata.startsWith("http")){url += "<a href='"+urldata +"'>link</a>"} else {url += urldata};
       
       
      items.push( "<div class='col-md-12'><div id='" + ann.id + "'><div class='col-md-6'><a target='_blank' href='"+ ann.links.html +"'>"  + ann.document.title +"</a></div><div class='col-md-6'><p>"  + content +"</p></div></div></div>" );
};
    $( "#hypothesisFeedResults" ).empty();
  $( "<div/>", {
    "class": "row",
    html: items.join( "" )
  }).appendTo( "#hypothesisFeedResults" );
  


$.ajaxSetup({ cache: false });
});
});