$("a[id^='quotation']").on('click', function () {
    /*        takes the data to put in the api query, the chapter xml:id and the id of the current item*/
    var workid = $(this).data('textid');
    var unit = $(this).data('unit');
    var getquotations = "/api/quotations/" + workid + '/' + unit; // this is the base for all calls here.
    /*on click query the api and send to ugarit reference and text */
    $.getJSON(getquotations, function (d) {
    console.log(d)
      if (d.total >= 1) {
      $("#AllQuotations" + unit).append('There are <span class="label label-warning">' + d.total + '</span> quotations of this passage')
        /*            make the parent div sortable*/
                for (var i = 0; i < d.total; i++) {
                    var n = (i + 1)
                    //console.log(i)
                    var q = d.quotations[i]
                    var passage = q.ref
                    var reference = passage.substr(passage.indexOf(unit))
                    var textwithlinks = addDillmannlinks(q.text)
/*          addDillmannlinks()   can be   found in versions.js*/
     
                            $("#AllQuotations" + unit).append('<div id="quotation' + q.source.id + '" class="row alert quote">Quotation of '+reference+' in ' + ' ' + q.source.title + ' (' + q.source.id + '): ' + textwithlinks + '</div>');
                        }
                    
      }
      else { $("#AllQuotations" + unit).text(d.info)}
    });
});