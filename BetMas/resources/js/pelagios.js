// $j optional alias to jQuery noConflict()
var $j = jQuery.noConflict();

$(document).on('ready', function () {
    var id = $("#pelagiosrelateditems").data("id") 
    var sameAs = $("#pelagiosrelateditems").data("sameAs") 
  var pelagioscall = 'https://peripleo.pelagios.org/peripleo/search?places=http%3A%2F%2Fbetamasaheft.eu%2Fplaces%2F' + id
   $.getJSON(pelagioscall,function(data) { 
   
   //console.log(data)
   if(data.total >= 1) {
   $("#pelagiosrelateditems").append('<h3>'+data.total+' related items from <a href="https://commons.pelagios.org/" target="_blank">Pelagios</a></h3>')
      
   $(data.items).each(function(linkshere){
   var relatedItem = '<div class="col-md-12"><p class="lead"><a href="'+this.homepage+'">' + this.title + '</a> in '+this.dataset_path["0"].title+'</p></div>'
       $("#pelagiosrelateditems").append(relatedItem)
   });}
});

    });
    
    $('.pelagios').on('click', function(){
var element = $(this)
console.log(element)
    var id = $(this).data("pelagiosid") 
    
console.log(id)
    var href= $(this).data("href") 
  var pelagioscall = 'https://peripleo.pelagios.org/peripleo/search?places=' + id
  
console.log(pelagioscall)
   var content = $('<ul/>')
   
   $.getJSON(pelagioscall,function(data) { 
   
   //console.log(data)
   if(data.total >= 1) {
   $(data.items).each(function(linkshere){
   var relatedItem = '<li class="nodot"><a href="'+this.homepage+'">' + this.title + '</a> in '+this.dataset_path["0"].title+'</li>'
       $(content).append(relatedItem)
       });
   
   $(element).popover({
            html: true,
            width : '300px',
            title: '<h3>'+data.total+' items from <a href="https://commons.pelagios.org/" target="_blank">Pelagios</a> related to <a href="'+href+'" target="_blank">this place [click]</a></h3>',
            content: content
        });
}        
});
});
