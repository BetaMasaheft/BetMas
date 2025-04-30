// $j optional alias to jQuery noConflict()
/*var $j = jQuery.noConflict();*/

$(document).on('ready', function () {
    var id = $("#pelagiosrelateditems").data("id") 
    var sameAs = $("#pelagiosrelateditems").data("sameAs") 
  var pelagioscall = 'https://peripleo.pelagios.org/peripleo/search?places=http%3A%2F%2Fbetamasaheft.eu%2Fplaces%2F' + id
   $.getJSON(pelagioscall,function(data) { 
   
   //console.log(data)
   if(data.total >= 1) {
   $("#pelagiosrelateditems").append('<h3>'+data.total+' related items from <a href="https://commons.pelagios.org/" target="_blank">Pelagios</a></h3>')
      
   $(data.items).each(function(linkshere){
   var relatedItem = '<div class="w3-container"><p class="w3-large"><a href="'+this.homepage+'">' + this.title + '</a> in '+this.dataset_path["0"].title+'</p></div>'
       $("#pelagiosrelateditems").append(relatedItem)
   });}
});

    });
    
    $('.pelagios').on('click', function(){
var element = $(this)
//console.log(element)
    var id = $(this).data("pelagiosid") 
    var placeID = $(this).data("value") 
//console.log(id)
    var href= $(this).data("href") 
  var pelagioscall = 'https://peripleo.pelagios.org/peripleo/search?places=' + id
  
//console.log(pelagioscall)
   var content = $('<div id="' + placeID + 'relations-content" class="popuptext w3-hide w3-tiny w3-padding" style="width: 260px;background-color: black;\
                color: white;text-align: center;border-radius: 6px;padding: 8px 0;position: absolute;left: 100%;top: 100%;margin-left: -130px;z-index: 999;overflow-y:auto">\
                </div>')
   var listrelations =$('<ul class="w3-hoverable"/>')
   var listtitle = $('<p/>')
    if ($(this).children('div').hasClass('popuptext')) {
       //console.log('there is already a popoup here, load it');
      var popupID = $(this).children('div').attr('id')
      //console.log(popupID)
      //console.log(popText)
        popup(popupID)
    } else {
    
   $.getJSON(pelagioscall,function(data) { 
   
   //console.log(data)
   if(data.total >= 1) {
   $(listtitle).append(data.total+' items from <a href="https://commons.pelagios.org/" target="_blank">Pelagios</a> related to <a href="'+href+'" target="_blank">this place</a>')

$(data.items).each(function(linkshere){
   
   var relatedItem = '<li class="nodot"><a href="'+this.homepage+'">' + this.title + '</a> in '+this.dataset_path["0"].title+'</li>'
       $(listrelations).append(relatedItem)
       });
       
   $(content).append(listtitle)
   $(content).append(listrelations)
   $(element).append(content)
   
}        
else {
   $(content).append('No related items from Pelagios')
   $(element).append(content)
    
}
});
}
});
