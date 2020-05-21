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
    //console.log(fullq)
    /*var split = fullq.split(/\s/g);
    console.log(split)
    for(var i = 0; i < split.length; i++) {
     */
    if (/[\*\?\~\(]/g.test(fullq)) {
        var q = fullq.replace(/[\*\?\~\(]/g, '')
    } else {
        var q = fullq
    }
    //console.log(q)
    $('span:contains("' + q + '")').toggleClass('queryTerm')
    /*}*/
});

function popup(id) {
  var x = document.getElementById(id);
  if (x.className.indexOf("w3-show") == -1) {
    x.className += " w3-show";
  } else { 
    x.className = x.className.replace(" w3-show", "");
  }
}

$('.word').each(function (wn) {
    
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
        /*        if it is the last word in the span, then add it straight, if it is somewhere else in the span sequence, then add back a white space
         * onmouseover='popup("+'"p'+wn+i+'"'+")' onmouseout='popup("+'"p'+wn+i+'"'+")'
         * */
        if (i == countwords - 1) {
            $(word).append($("<span class='alpheios-word popup' data-value='p" + wn + i + "'>" + nostops.w + nostops.stop + "\
            <span class='popuptext w3-hide w3-tiny w3-padding' id='p" + wn + i + "'>\
            Search " + nostops.w + " :<br/>\
            <a href='/facet.html?query=" + nostops.w + "' target='_blank'>in Beta maṣāḥǝft</a><br/>\
            <a href='/morpho?query=" + nostops.w + "' target='_blank'>in the Gǝʿǝz Morphological Parser</a><br/>\
            <a href='/morpho/corpus?query=" + nostops.w + "&type=string' target='_blank'>in the TraCES annotations</a><br/>\
            <a href='" + url + parm + nostops.w + "' target='_blank'>in the Online Lexicon</a><br/>\
            Double click on the word to load the results of the morphological parsing with Alpheios.\
            </span> </span>"));
        } else {
            /*onmouseover='popup("+'"p'+wn+i+'"'+")' onmouseout='popup("+'"p'+wn+i+'"'+")'*/
            $(word).append($("<span class='alpheios-word popup' data-value='p" + wn + i + "'>" + nostops.w + nostops.stop + '&nbsp;' + "\
            <span class='popuptext w3-hide w3-tiny w3-padding' id='p" + wn + i + "'>\
            Search " + nostops.w + " :<br/>\
            <a href='/facet.html?query=" + nostops.w + "' target='_blank'>in Beta maṣāḥǝft</a><br/>\
            <a href='/morpho?query=" + nostops.w + "' target='_blank'>in the Gǝʿǝz Morphological Parser</a><br/>\
            <a href='/morpho/corpus?query=" + nostops.w + "&type=string' target='_blank'>in the TraCES annotations</a><br/>\
            <a href='" + url + parm + nostops.w + "' target='_blank'>in the Online Lexicon</a><br/>\
            Double click on the word to load the results of the morphological parsing with Alpheios.\
            </span> </span>"));
        }
    });
});


$('.popup').on('mouseover mouseout',function () {
    var id = $(this).data('value') 
    console.log(id)
    popup(id)
})




$('.diplomaticHighlight').on('change', function () {
    $('span.invocation span.word a').toggleClass('invocation');
    $('span.clauses span.word a').toggleClass('clauses');
    $('span.conclusion span.word a').toggleClass('conclusion');
    $('span.listOfPersons span.word a').toggleClass('listOfPersons');
    $('span.motif span.word a').toggleClass('motif');
    $('span.provision span.word a').toggleClass('provision');
    $('span.suscription span.word a').toggleClass('suscription');
    if ($(this).next().is('br')) {
    } else {
        $(this).after('\
        <br/><span class="invocation w3-tag w3-red">invocation</span>\
        <a role="button" class="w3-button w3-gray" target="_blank" href="/diplomatique.html?interpret=%23invocation">compare</a>\
        <br/><span class="clauses  w3-tag w3-red">clauses</span>\
        <a role="button" class="w3-button w3-gray" target="_blank" href="/diplomatique.html?interpret=%23clauses">compare</a>\
        <br/><span class="conclusion w3-tag w3-red">conclusion</span>\
        <a role="button" class="w3-button w3-gray" target="_blank" href="/diplomatique.html?interpret=%23conclusion">compare</a>\
        <br/><span class="listOfPersons  w3-tag w3-red">listOfPersons</span>\
        <a role="button" class="w3-button w3-gray" target="_blank" href="/diplomatique.html?interpret=%23listOfPersons">compare</a>\
        <br/><span class="motif w3-tag w3-red">motif</span>\
        <a role="button" class="w3-button w3-gray"  target="_blank" href="/diplomatique.html?interpret=%23motif">compare</a>\
        <br/><span class="provision w3-tag w3-red">provision</span>\
        <a role="button" class="w3-button w3-gray" target="_blank" href="/diplomatique.html?interpret=%23provision">compare</a>\
        <br/><span class="suscription w3-tag w3-red">suscription</span>\
        <a role="button" class="w3-button w3-gray" target="_blank" href="/diplomatique.html?interpret=%23suscription">compare</a><br/>')
    }
});