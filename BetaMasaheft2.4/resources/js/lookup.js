$('#gsf').on('submit', function(){
  var controls = form.elements;
  console.log(controls)
  for (var i=0, iLen=controls.length; i<iLen; i++) {
    controls[i].disabled = controls[i].value == '';
  }
    
});

$(document).on('ready', function () {
    

   $("#GoTo").on('change paste keyup', function () {
 
   var collection = $("#GoTo").data('value')
   var searchterm = $("#GoTo").val()
   console.log(searchterm)
   var element = ""
   switch(collection) {
    case 'persons':
       element = 'persName'
        break;
   case 'places':
       element = 'placeName'
        break;
  case 'institutions':
       element = 'placeName'
        break;
        case 'all':
       element = 'title'
        break;
    default:
         element = 'title'
};
   console.log(searchterm)
   // this will look ONLY in one element for each type of record
   var apiurl = '/api/search?element='+element+'&collection=' + collection + ' &q='
   var searchurl = apiurl + searchterm
    $.getJSON(searchurl, function (data) {
        
        var options = ""
        for (var i = 0; i < data.total; i++) {
           var option = '<option value="'+ data.items[i].id +'">' +  data.items[i].title + '</option>'
            options+= option
           
        };
   
  $("#gotohits").html(options) 
   });
   
   });
   
   $('#clickandgoto').on('click', function(){
      
       url = $('#GoTo').val();
       window.open(url);
 
   });
   
   
   
   
   
   $("#GoToId").on('change paste keyup', function () {
    
   var collection = $("#GoToId").data('value')
   var searchterm = $("#GoToId").val()
   if(searchterm.length >= 3 ) {
   // this will look ONLY in one element for each type of record
   var apiurl = '/api/idlookup?id='
   var searchurl = apiurl + searchterm
   
    $.getJSON(searchurl, function (data) {
        
        var options = ""
        for (var i = 0; i < data.total; i++) {
           var option = '<option value="'+ data.items[i].id +'">' +  data.items[i].id + '</option>'
            options+= option
            console.log(option)
           
        };
        
   
  $("#gotoID").html(options) 
   });
   }
   });
   
   $('#clickandgotoID').on('click', function(){
      
       url = $('#GoToId').val();
       window.open(url);
 
   });
   $('#clickandgotoRepoID').on('click', function(){
      
       url = $('#GoToRepo').val();
       fullurl = '/manuscripts/' + url + '/list'
       console.log(fullurl)
       window.open(fullurl);
 
   });
   $('#clickandgotoCatalogueID').on('click', function(){
      
       url = $('#GoToCatalogue').val();
       fullurl = '/catalogues/' + url + '/list'
       console.log(fullurl)
       window.open(fullurl);
 
   });
   
});