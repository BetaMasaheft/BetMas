
$(document).on('ready', function () {
    var id = $("#Chojnacki").data("id") 
  var restcall = '/api/Chojnacki/' + id
   $.getJSON(restcall,function(data) { 
   
   //console.log(data)
   if(data.total >= 1) {
   $("#Chojnacki").append('<h3>'+data.total+' related items from <a href="https://digi.vatlib.it/stp/Chojnacki" target="_blank">Chojnacki Archive at the Vatican Library</a></h3>')
      
   $(data.ChojnackItems).each(function(Choj){
   var relatedItem = '<div class="col-md-12"><p><a target="_blank" href="'+ this.link+'">' + this.name + '</a></p></div>'
       $("#Chojnacki").append(relatedItem)
   });
   
   $("#Chojnacki").addClass('col-md-12 alert alert-success')
   }
});

});