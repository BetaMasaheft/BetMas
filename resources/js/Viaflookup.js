$(document).on('ready', function () {
    

   $("#VIAF").on('change paste keyup', function () {
 
   var collection = $("#VIAF").data('value')
   var searchterm = $("#VIAF").val()
   
   console.log(searchterm)
   // this will look ONLY in one element for each type of record
   var apiurl = 'http://www.viaf.org/viaf/AutoSuggest?query='
   var searchurl = apiurl + searchterm
    console.log(searchurl)
    $.getJSON(searchurl, function (data) {
         console.log(data)
        var options = ""
        for (var i = 0; i < data.length; i++) {
           var option = '<option value="'+ data.result[i].viafid +'">' +  data.result[i].term + '</option>'
            options+= option
           
        };
   
  $("#VIAFhits").html(options) 
   });
   
   });
   
   
});