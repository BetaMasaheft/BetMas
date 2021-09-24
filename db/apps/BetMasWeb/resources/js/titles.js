/* assumes a.MainTitle with data-value='ID' and calls the restxq api api:get-FormattedTitle() to retrive the correct citation text to be used*/
$(document).on('ready', function () {
    checkfortitles();
    checkforWordCounts();
});


function checkfortitles() {
    if ($('.MainTitle')) {
        printTitle();
    } else {
        setTimeout(printTitle, 50);
    }
};


function checkforWordCounts() {
    if ($('.WordCount')) {
        printWC();
    } else {
        setTimeout(printWC, 50);
    }
};


function printWC() {
   
   $(".WordCount").each(function () {
      var el = this
      var MSid = $(this).data('msid')  
        var Wid = $(this).data('wid') 
         var WDcall = "/api/WordCount/" + MSid + '/' + Wid
         $(el).load(WDcall)
    });
    
};


function printTitle() {
var ids = []
/*expected result: Canonical Title = CAe 1234 = CAVT 21234 = CC 2131*/
    $(".MainTitle").each(function () {
        var el = this
        var id = $(this).data('value')
        var str = String(id)
         if(ids.indexOf(str) == -1){ids.push(str)} else {}

    });
    
    //console.log(ids)
    
    $(ids).each(function (index, id) {
       var escapedid = id.replace("#", "/")
       var escapedid = escapedid.replace(":", "_")
       var mainid = ''
        if(id.match('#')){mainid = id.substring(0, id.indexOf('#'))} else {mainid = id}
       
        var els = $("[data-value='"+id+"'][class='MainTitle']")
     //console.log(els)
       /*        the call for the title takes id/subid/title and returns a string*/
        var restcall = "/api/" + escapedid + '/title'
/*        the call for the clavis ids takes clavis/id WITHOUT anchors and returns a JSON object*/
        var claviscall = "/api/clavis/" + mainid
        
/*        put in the element the title from the api call for it. */
$(els).load(restcall);
 
/*        if the title of a literary work is requested, then add after the title string a equal sign, the clavis abbreviation and the corresponding value  */
        if (escapedid.match("^LIT") && !escapedid.match("IHA$")) {
/*        calls the clavis api*/
            $.getJSON(claviscall, function (data) {
/*            saves the clavis aethiopica  id from the id */
            var claviscae = data.CAe.substring(3, 7)
                var cae = "<span> = CAe " + claviscae + '</span>'
/*                for each other clavis match add a equal sign and the value*/
                $.each(data.clavis, function (i, item) {
                if(item !== null){
                    var clavis = "<span> = " + i + " " + item + '</span>'
                 //console.log(clavis); 
                 $(clavis).insertAfter($(els))
                 }
                })
/*                before any other clavis, adds after the title the Clavis Aethiopica id*/
                $(cae).insertAfter($(els))
            });
        }
        });
};