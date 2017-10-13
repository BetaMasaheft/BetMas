$(document).ready(function () {

$('#seealsoSelector').change(function (showthefilters) {
    var keyword = $('#seealsoSelector').val()
    //console.log(keyword)
    var element = $("#seealsoSelector option:selected").parent().attr('label')
    var apiurl = '/api/sharedKeyword/'
    var param = '?element=' + encodeURIComponent(element)
    var call = apiurl + keyword + param
    $.getJSON(call, function (data) {
     //console.log(data)
        var items =[];
        if(data.total == 1){
            var match = data.hits
                var id = match.id; 
               //  console.log(id)
                var title = match.title;
               var card = "<div class='card'><div id='"  + id + "' class='card-block'><div class='card-title'><a href='/"   + id + "'>" + title + "</a></div></div></div>"
                items.push(card);
            
        }
        else if (data.total == 0){
          var card = "<div class='card'><div class='card-block'><div class='card-title'>no results</div><div class='card-text'>Sorry, this query returned no result</div></div></div>"
                items.push(card);
            
        }
        else {
        for (var i = 0; i < data.total; i++) {
       //console.log(data.hits[i])
                var match = data.hits[i]
                var id = match.id; 
               // console.log(id)
                var title = match.title;
               var card = "<div class='card'><div id='"  + id + "' class='card-block'><div class='card-title'><a href='/"   + id + "'>" + title + "</a></div></div></div>"
                items.push(card);
    
            };}
            $("#SeeAlsoResults").empty();
      $("<div/>", {
                'class': 'card-columns',
                html: items.join("")
            }).appendTo("#SeeAlsoResults");
            
    });
});


});


$(document).on({
    ajaxStart: function() { $("img#loading").show();   },
     ajaxStop: function() {  $("img#loading").hide(); }    
});
