$(".parallelversion").on('click', function () {
/*        takes the data to put in the api query, the chapter xml:id and the id of the current item*/
        var workid = $(this).data('textid');
        var unit = $(this).data('unit');
        var getVersions = "/api/SPARQL/versions/" + workid + '/' + unit; // this is the base for all calls here.
        /*on click query the api and send to ugarit reference and text */
        $.getJSON(getVersions, function (d) {
       // console.log(d)
/*        if there are more then one version (the current will be excluded by the api call) then print the results*/
            if (d.total >= 1) {
/*            make the parent div sortable*/
                for (var i = 0; i < d.total; i++) {
                    var n = (i + 1)
                    //console.log(i)
                    var vers = d.versions[i].version
                    var textwithlinks = addDillmannlinks(vers.text)
                    var source = ''
                    if (vers.source.uniqueWitness) {
                    //console.log(vers.source.id + 'has a unique witness')
                        source = vers.source.uniqueWitness
                        $("#versions").append('<div id="version' + vers.source.id + '" class="row alert version"><h3>Version ' +  ' ' + vers.source.title + ' (' + vers.source.id + ')' + '</h3><p class="lead">Edition: ' + source + '</p>' + textwithlinks + '</div>');
                            
                    } else {
                        var editor = vers.source.ed
                        //console.log(vers.source.id + ' has an edition ' + editor)
                        if (/bm:/g.test(editor)) {
                        //console.log(vers.source.id + 'has a reference to a book')
                           
                               var bibl; 
                               if($('span[data-value="'+editor+'"]').length > 1){bibl = $('span[data-value="'+editor+'"]').html()} else {bibl='<span class="Zotero Zotero-full" data-value="'+editor+'"/>'}
                              // console.log(bibl)
                                $("#versions").after('<div id="version' + vers.source.id + '" class="row alert version"><h3>Version ' + ' ' + vers.source.title + ' (' + vers.source.id + ')' + '</h3><p class="lead">Edition: '+bibl+'</p>' + textwithlinks + '</div>');
                               checkforbiblio();
                        } else {
                        
                            $("#versions").after('<div id="version' + vers.source.id + '" class="row alert version"><h3>Version ' + ' ' + vers.source.title + ' (' + vers.source.id + ')' + '</h3><p class="lead">Edition: ' + editor + '</p>' + textwithlinks + '</div>');
                        }
                    }
                }
            }
            else {$(".parallelversion").attr('disabled', 'disabled')}
        });
        
    });


function addDillmannlinks(textinput) {
   var allword = $('<div/>')
    /*make all spaces a single space*/
    var normspace = textinput.replace(/\s\s+/g, ' ');
    /*    split the string in words at the white space*/
    var textinputsplit = normspace.split(" ");
    var countwords = textinputsplit.length;
    /*    delete all in the element*/
    $(this).empty();
    /*    build fuzzy query search string for lexicon*/
    var url = '/Dillmann/?mode=fuzzy'
    var parm = '&q='
    /*    for each item in the split sequence, which shoud be a word add to the emptied element the word with a link*/
    $.each(textinputsplit, function (i, v) {
        /*initialize an empty object which will contain the word and the punctionation, to be able to print back all but use in the query the string without punctuation*/
        var nostops = {
        }
        /*check if there is an end of word punctuation mark*/
        if (v.endsWith('፡')) {
            nostops.w = v.substr(0, v.indexOf('፡'));
            nostops.stop = '፡'
        } else if (v.endsWith('።')) {
            nostops.w = v.substr(0, v.indexOf('።'));
            nostops.stop = '።'
        } else {
            nostops.w = v; nostops.stop = ''
        }
/*        if it is the last word in the span, then add it straight, if it is somewhere else in the span sequence, then add back a white space*/
       if (i == countwords - 1) {
            $(allword).append($("<a target='_blank' href='" + url + parm + nostops.w + "'/>").text(nostops.w + nostops.stop));
        } else {
            $(allword).append($("<a target='_blank' href='" + url + parm + nostops.w + "'/>").text(nostops.w + nostops.stop + ' '));
        }
    });
    return  $(allword).html();
}