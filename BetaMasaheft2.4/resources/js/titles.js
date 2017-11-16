/* assumes a.MainTitle with data-value='ID' and calls the restxq api api:get-FormattedTitle() to retrive the correct citation text to be used*/
$(document).on('ready', function () {
    checkfortitles();
});


function checkfortitles() {
    if ($('.MainTitle')) {
        printTitle();
    } else {
        setTimeout(printTitle, 50);
    }
};

function printTitle() {
/*expected result: Canonical Title = CAe 1234 = CAVT 21234 = CC 2131*/
    $(".MainTitle").each(function () {
        var el = this
        var id = $(this).data('value')
        var str = String(id)
        var escapedid = str.replace("#", "/")
        var mainid = ''
        if(str.match('#')){mainid = str.substring(0, str.indexOf('#'))} else {mainid = str}
        
/*        the call for the title takes id/subid/title and returns a string*/
        var restcall = "/api/" + escapedid + '/title'
/*        the call for the clavis ids takes clavis/id WITHOUT anchors and returns a JSON object*/
        var claviscall = "/api/clavis/" + mainid
        
/*        put in the element the title from the api call for it. */
        $(el).load(restcall);
        
/*        if the title of a literary work is requested, then add after the title string a equal sign, the clavis abbreviation and the corresponding value  */
        if (escapedid.match("^LIT")) {
/*        calls the clavis api*/
            $.getJSON(claviscall, function (data) {
/*            saves the clavis aethiopica  id from the id */
            var claviscae = data.CAe.substring(3, 7)
                var cae = "<span> = CAe " + claviscae + '</span>'
/*                for each other clavis match add a equal sign and the value*/
                $.each(data.clavis, function (i, item) {
                if(item !== null){
                    var clavis = "<span> = " + i + " " + item + '</span>'
                 console.log(clavis); 
                 $(clavis).insertAfter($(el))
                 }
                })
/*                before any other clavis, adds after the title the Clavis Aethiopica id*/
                $(cae).insertAfter($(el))
            });
        }
    });
};