/* assumes a.MainTitle with data-value='ID' and calls the restxq api api:get-FormattedTitle() to retrive the correct citation text to be used*/
 $(document).on('ready', function () {
 checkfortitles();
});


function checkfortitles() {
if($('.MainTitle')){
    printTitle();  
  } else {
    setTimeout(printTitle, 50); 
  }
 
};

function printTitle() {
$(".MainTitle").each(function() {
           var el = this
           var id = $(this).data('value')
           var str = String(id)
           var escapedid = str.replace("#", "/")
           var restcall = "/api/" + escapedid + '/title'
           
   $(el).load(restcall);
});
};