var getUrlParameter = function getUrlParameter(sParam) {
    var sPageURL = decodeURIComponent(window.location.search.substring(1)),
    sURLVariables = sPageURL.split('&'),
    sParameterName,
    i;
    
    for (i = 0; i < sURLVariables.length; i++) {
        sParameterName = sURLVariables[i].split('=');
        
        if (sParameterName[0] === sParam) {
            return sParameterName[1] === undefined ? true: sParameterName[1];
        }
    }
};

$(document).ready(function () {
    var fullq = getUrlParameter('hi');
    console.log(fullq)
    /*var split = fullq.split(/\s/g);
    console.log(split)
    for(var i = 0; i < split.length; i++) {
     */
    if (/[\*\?\~\(]/g.test(fullq)) {
        var q = fullq.replace(/[\*\?\~\(]/g, '')
    } else {
        var q = fullq
    }
    console.log(q)
    $('span:contains("' + q + '")').toggleClass('queryTerm')
    /*}*/
});

$('.word').each(function () {
    
    var word = $(this)
    /*make all spaces a single space*/
    var normspace = $(word).text().replace(/\s\s+/g, ' ');
    /*    split the string in words at the white space*/
    var words = normspace.split(" ");
    var countwords = words.length;
    /*    delete all in the element*/
    $(this).empty();
    /*    build fuzzy query search string for lexicon*/
    var url = '/Dillmann/?mode=fuzzy'
    var parm = '&q='
    /*    for each item in the split sequence, which shoud be a word add to the emptied element the word with a link*/
    $.each(words, function (i, v) {
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
            $(word).append($("<a target='_blank' href='" + url + parm + nostops.w + "'/>").text(nostops.w + nostops.stop));
        } else {
            $(word).append($("<a target='_blank' href='" + url + parm + nostops.w + "'/>").text(nostops.w + nostops.stop + ' '));
        }
    });
});