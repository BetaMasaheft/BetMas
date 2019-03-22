$('#seealsoSelector').change(function (showthefilters) {
    var keyword = $('#seealsoSelector').val()
//    console.log(keyword)
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
               var card = "<div class='w3-card-4'><div id='"  + id + "' class='w3-container'><div class='w3-large'><a href='/"   + id + "'>" + title + "</a></div></div></div>"
                items.push(card);
            
        }
        else if (data.total == 0){
          var card = "<div class='w3-card-4'><div class='w3-container'><div class='w3-large'>no results</div><div class='w3-content'>Sorry, this query returned no result</div></div></div>"
                items.push(card);
            
        }
        else {
        for (var i = 0; i < data.total; i++) {
       //console.log(data.hits[i])
                var match = data.hits[i]
                var id = match.id; 
               // console.log(id)
                var title = match.title;
               var card = "<div class='w3-card-4'><div id='"  + id + "' class='w3-container'><div class='w3-large'><a href='/"   + id + "'>" + title + "</a></div></div></div>"
                items.push(card);
    
            };}
            $("#SeeAlsoResults").empty();
      $("<div/>", {
                'class': 'card-columns',
                html: items.join("")
            }).appendTo("#SeeAlsoResults");
            
    });
});




$(document).on({
    ajaxStart: function() { 
        $("img#loading").show(); 
        $('#mainPDF').attr('disabled','disabled')},
     ajaxStop: function() {  $("img#loading").hide();
     
         $('#mainPDF').removeAttr('disabled')
     }    
});
