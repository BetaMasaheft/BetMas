
$(document).on('ready', function () {

 var input = $("#hypothesisFeedResults").data('value')
var url = "https://hypothes.is/api/search?tag=BetMas:" + input + "&limit=200"
//console.log(url)

$.ajaxSetup({ cache: true });
$.getJSON( url, function( data ) {
//console.log(data)
  var items = [];
       for (var i = 0; i < data.total; i++) {
       var ann = data.rows[i]
       var content = "";
       var contentdata = ann.text
       if(contentdata.startsWith("http")){content += "<a href='"+contentdata +"'>link</a>"} else {content += contentdata};
       var url = "";
       var urldata = ann.uri
       if(urldata.startsWith("http")){url += "<a href='"+urldata +"'>link</a>"} else {url += urldata};
       var user = ann.user
       var userLink = "<a href='"+ user+"'>"+user.substring(0, user.indexOf('@')).replace('acct:', '')+"</a>" 
       
      items.push( "<tr id='" + ann.id + "' ><td ><a target='_blank' href='"+ ann.links.html +"'>"  + ann.document.title +"</a> ["+url+"]</td><td><p>"  + content +" (annotation by "+userLink+")</p></td></tr>" );
};
    $( "#hypothesisFeedResults" ).empty();
  $( "<table/>", {
    "class": "w3-table w3-hoverable",
    html: items.join( "" )
  }).appendTo( "#hypothesisFeedResults" );
  


$.ajaxSetup({ cache: false });
});
});