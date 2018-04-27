$(document).on('ready', function(){

var formblock = $('<div  class="control-group"></div>')
$(formblock).append('<small class="form-text text-muted">Select one or more type of document or addition</small>')
    $('.additionType').each(function(){
       var id = $(this).data('value')
       var name = $(this).text()
        var checkbox = '<label class="checkbox"><input type="checkbox" value="'+id+'" name="type"/>'+name+'</label>'
        $(formblock).append($(checkbox))
    });
     $('#additiontypes').html(formblock)
   
   $('p.gez').each(function(){
       var txt = $(this).text()
       var textwithlinks = addDillmannlinks(txt)
       $(this).html(textwithlinks)
   })
   
   
   
   
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