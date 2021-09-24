$(document).on({
    ajaxStart: function () {
        $("img#loadingform").show();
    },
    ajaxStop: function () {
        $("img#loadingform").hide();
    }
});


function callformpart(paraname, id, context) {
    var call = '/api/SearchFormParts/' + paraname + '?cont='+ context
    // check first that the element is not there already
    var myElem = document.getElementById(id);
    // if it is not there, load it
    if (myElem === null) {
        $.ajax(call, {
            success: function (data) {
                $("#AddFilters").append(data);
            }
        });
    }
    // else it has already been loaded, therefore simply show it.
    var jid = '#' + id
    $(jid).toggle();
};

$(document).ready(function () {
    // the checkboxes are all unchecked on load, expected event is that some of them is clicked. thus on click do something
    $('input[type=checkbox]').change(function (showthefilters) {
        var value = $(this).attr("value");
        console.log(value)

         var context = $(this).data("context");
         console.log(context)
        // if the value is checked, then look which value it is
        if ($(this).is(':checked')) {
            switch (value) {
                //   for each value call the appropriate html with function to generate the form selector
                case "contents":
                callformpart("contents", "contentsform", context);
                break;
                case "origPlace":
                callformpart("origPlace", "origPlaceform", context);
                break;
                case "script":
                callformpart("script", "scriptform", context);
                break;
               case "scribe":
                callformpart("scribe", "scribeform", context);
                break;
                case "donor":
                callformpart("donor", "donorform", context);
                break;
                case "patron":
                callformpart("patron", "patronform", context);
                break;
                case "parchmentMaker":
                callformpart("ParMaker", "parmakerform", context);
                break;
                case "binder":
                callformpart("binder", "binderform", context);
                break;
                case "owner":
                callformpart("owner", "ownerform", context);
                break;
                case "objectType":
                callformpart("objecttype", "otform", context);
                break;
                case "material":
                callformpart("material", "materialform", context);
                break;
                case "bmaterial":
                callformpart("bmaterial", "bmaterialform", context);
                break;
                case "authors":
                callformpart("authors", "authorsform", context);
                break;
                case "occupation":
                callformpart("occupation", "occupationform", context);
                break;
                case "gender":
                callformpart("gender", "genderform", context);
                break;
                case "placeType":
                callformpart("placetype", "placetypeform", context);
                break;
                case "tabots":
                callformpart("tabots", "tabotsform", context);
                break;
            }
        } else {
            // if the user clicks the checked box (which should then become unchecked), then hide what has been loaded or was there already
            switch (value) {
                case "languages":
                $('#languages').hide();
                break;
                case "keywords":
                $('#keywords').hide();
                break;
                 case "folia":
                $('#leavesform').hide();
                break;
                case "quires":
                $('#quiresform').hide();
                break;
                case "quiresComp":
                $('#quiresCompform').hide();
                break;
                case "writtenLines":
                $('#WLform').hide();
                break;
                case "script":
                $('#scriptform').hide();
                break;
                case "scribe":
                $('#scribeform').hide();
                break;
                case "donor":
                $('#donorform').hide();
                break;
                case "patron":
                $('#patronform').hide();
                break;
                case "owner":
                $('#ownerform').hide();
                break;
                case "parchmentMaker":
                $('#parmakerform').hide();
                break;
                case "binder":
                $('#binderform').hide();
                break;
                case "objectType":
                $('#otform').hide();
                break;
                case "material":
                $('#materialform').hide();
                break;
                case "bmaterial":
                $('#bmaterialform').hide();
                break;
                case "authors":
                $('#authorsform').hide();
                break;
                case "occupation":
                $('#occupationform').hide();
                break;
                case "gender":
                $('#genderform').hide();
                break;
                case "placeType":
                $('#placetypeform').hide();
                break;
                case "tabots":
                $('#tabotsform').hide();
                break;
            }
        }
    });


});
