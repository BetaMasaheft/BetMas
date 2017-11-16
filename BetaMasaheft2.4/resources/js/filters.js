


 $('#tooglesearchfield').click(function() {
        $('#searchform').toggle( "slow");
        });

$('#collectionfilter').on('change', function () {
    if ($(this).val() === "mss") {
        $("#manuscriptsFilters").show()
    } else {
        $("#manuscriptsFilters").hide()
        $('#insform').hide();
    }
    
    if ($(this).val() === "works") {
        $("#worksFilters").show()
    } else {
        $("#worksFilters").hide()
    }
    
    if ($(this).val() === "pers") {
        $("#persFilters").show()
    } else {
        $("#persFilters").hide()
    }
    
    if ($(this).val() === "places") {
        $("#placesFilters").show()
    } else {
        $("#placesFilters").hide()
    }
});

function callformpart(file, id) {
    
    // check first that the element is not there already
    var myElem = document.getElementById(id);
    // if it is not there, load it
    if (myElem === null) {
        $.ajax(file, {
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
        // if the value is checked, then look which value it is
        if ($(this).is(':checked')) {
            switch (value) {
                //   for each value call the appropriate html with function to generate the form selector
                case "languages":
                callformpart("formlanguages.html", "languages");
                break;
                case "keywords":
                callformpart("formkeywords.html", "keywords");
                break;
                case "relations":
                callformpart("formrelations.html", "relations");
                break;
                case "references":
                callformpart("formref.html", "containsRef");
                break;
                case "xpath":
                callformpart("formxpath.html", "xpathform");
                break;
                case "date":
                callformpart("formdates.html", "datesform");
                break;
                case "msstargets":
                callformpart("formtargetmss.html", "mssform");
                break;
                case "folia":
                callformpart("formfolia.html", "leavesform");
                break;
                case "quires":
                callformpart("formquires.html", "quiresform");
                break;
                case "writtenLines":
                callformpart("formWL.html", "WLform");
                break;
                case "script":
                callformpart("formscripts.html", "scriptform");
                break;
                case "institutions":
                callformpart("forminstitutions.html", "insform");
                break;
                case "scribe":
                callformpart("formscribes.html", "scribeform");
                break;
                case "donor":
                callformpart("formdonor.html", "donorform");
                break;
                case "patron":
                callformpart("formpatron.html", "patronform");
                break;
                case "parchmentMaker":
                callformpart("formParMaker.html", "parmakerform");
                break;
                
                case "role":
                callformpart("formrole.html", "roleform");
                break;
                case "binder":
                callformpart("formbinder.html", "binderform");
                break;
                case "dimensions":
                callformpart("formdimensions.html", "dimensionsform");
                break;
                case "owner":
                callformpart("formowner.html", "ownerform");
                break;
                case "contents":
                callformpart("formcontents.html", "contentform");
                break;
                case "objectType":
                callformpart("formobjecttype.html", "otform");
                break;
                case "material":
                callformpart("formmaterial.html", "materialform");
                break;
                case "bmaterial":
                callformpart("formbmaterial.html", "bmaterialform");
                break;
                case "target-works":
                callformpart("formworks.html", "targetworksform");
                break;
                case "authors":
                callformpart("formauthors.html", "authorsform");
                break;
                case "occupation":
                callformpart("formoccupation.html", "occupationform");
                break;
                case "gender":
                callformpart("formgender.html", "genderform");
                break;
                case "placeType":
                callformpart("formplacetype.html", "placetypeform");
                break;
                case "tabots":
                callformpart("formtabots.html", "tabotsform");
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
                case "relations":
                $('#relations').hide();
                break;
                case "references":
                $('#containsRef').hide();
                break;
                case "xpath":
                $('#xpathform').hide();
                break;
                case "date":
                $('#datesform').hide();
                break;
                case "mss":
                $('#mssform').hide();
                break;
                case "works":
                $('#worksform').hide();
                break;
                case "pers":
                $('#persform').hide();
                break;
                case "places":
                $('#placesform').hide();
                break;
                case "folia":
                $('#leavesform').hide();
                break;
                case "quires":
                $('#quiresform').hide();
                break;
                case "writtenLines":
                $('#WLform').hide();
                break;
                case "script":
                $('#scriptform').hide();
                break;
                case "institutions":
                $('#insform').hide();
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
                case "dimensions":
                $('#dimensionsform').hide();
                break;
                case "contents":
                $('#contentform').hide();
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
                case "target-works":
                $('#targetworksform').hide();
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


$(document).on('change', '#target-ins', function() {
    var ins = $(this).val();
    var apicall = '/api/manuscripts/list/json?perpage=2000&repo='+ins
    $.getJSON(apicall, function (data) {
    console.log(data)
    var options = ''
    for (var i = 0; i < data.total; i++) {
   
   var ms = data.items[i]
   console.log(ms)
    options += '<option value="'+ms.id+'" >'+ms.title+'</option>'
    }
        var targetmss = '<div class="form-group list mss" data-toggle="tooltip" data-placement="left" title="Select Manuscripts individually" id="mssform"><div class="col-md-9 col-xs-9"><label class="control-label col-sm-3" for="target-ms">Manuscripts</label><div class="col-sm-9"><select multiple="multiple" name="target-ms" id="target-ms" class="form-control">'+ 
        options + '</select></div></div><div class="col-md-3 col-xs-3">Here you can specify exactly in which Manuscripts records you want tosearch.</div></div>'
        $(targetmss).insertAfter($('#insform'))
        
    });
    
});