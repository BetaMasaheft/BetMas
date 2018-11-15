// add test as templating page in the app and load this file there as well for testing with working call to api
//all sparqlresult property paths are to be updated to deal with the json returned from the query

$(document).on('ready', function () {
    var id = $('#SdCTable').data('id')
    var extent = $('#SdCTable').data('extent')
    var manifest = $('#SdCTable').data('images')
    var sourcemanifest = $('#SdCTable').data('imagesSource')
    var query = "SELECT DISTINCT ?locusFrom ?locusTo ?locusTarget ?type ?name \
    WHERE {?resource dcterms:hasPart ?part .\
    ?part a ?class;\
    OPTIONAL {?part bm:hasLocus ?locus \
    OPTIONAL{?locus bm:locusTarget ?locusTarget} \
    OPTIONAL{?locus bm:locusFrom ?locusFrom} \
    OPTIONAL{?locus bm:locusTo ?locusTo}}\
    BIND('" + id + "' as ?id)\
    BIND(STR(?resource) AS ?r)\
    BIND(STR(?part) AS ?p)\
    FILTER(contains(?r, ?id))\
    BIND(STR(?class) AS ?c)\
    FILTER ( strStarts(?c, 'https://w3id.org/sdc/ontology#') ||  contains(?c, 'quire')||  contains(?c, 'hand') || contains(?c, 'decoration') || contains(?c, 'addition') )\
    BIND(IF(regex(?p, 'addition','i'), 'y', 'n') as ?addition)\
    BIND(IF(?addition = 'y', 'addition', IF(regex(?c, '#','i'), STRAFTER(?c, '#'), STRAFTER(?c, 'http://betamasaheft.eu/')))   AS ?type)\
    BIND(strafter(?p, 'http://betamasaheft.eu/') as ?uri)\
    BIND(replace(?uri , '/', ' ') AS ?name)}"
    
    var apicall = '/api/SPARQL/json?query=' + encodeURIComponent(query)
    
      $("#graphloadingstatus").text('Querying SPARQL data')
    $.getJSON(apicall, function (sparqlresult) {
    //console.log(sparqlresult)
        var table =[];
      $("#graphloadingstatus").text('building the table')
        for (var i = 0; i < extent; i++) {
            var f = (i + 1)
            var recto = new row(f + 'r')
            table.push(recto)
            var verso = new row(f + 'v')
            table.push(verso)
        };
        
        
        function row(number) {
            this.quire = ''
            this.folio = number
            this.UniMat = ''
            this.UniMarq = ''
            this.UniCah = ''
            this.UniCont = ''
            this.addition = ''
            this.UniMain = ''
            this.UniEcri = ''
            this.UniRegl = ''
            this.UniMep = ''
            this.decoration = ''
            this.UniProd = ''
        }
        
        //console.log(table)
        var results = sparqlresult.results.bindings
        var reslength = results.length
        //console.log(reslength)
        
      $("#graphloadingstatus").text('going through the results of the SPARQL query')
        $(results).each(function(i){
            var unit = this
            var Lf = ''
            if ('locusFrom' in unit) {
                Lf = unit.locusFrom.value
            }
            var Lto = ''
            if ('locusTo' in unit) {
                Lto = unit.locusTo.value
            }
            var Lta = ''
            if ('locusTarget' in unit) {
                Lta = unit.locusTarget.value
            }
            
            var Type = ''
            if ('type' in unit) {
                Type = unit.type.value
            }
            var name = ''
            if ('name' in unit) {
                name = unit.name.value
            }
            // here build a sequence of all folio to which the definition applies, e.g. if locusFrom = 1r and locusTo = 8v, sequence should be [1r,1v,2r,2v]
            var range =[]
            //locus cases to fill the range
            // there is no indication, apply to all
            // there are from and to
            if (Lf != '' && Lto != '') {
                var numericLf = Lf.match(/\d+/)
                var numericLto = Lto.match(/\d+/)
                var last = parseInt(numericLto) + 1
                // console.log(numericLf + ' - ' + numericLto)
                for (q = numericLf; q < last; q++) {
                    //console.log(q)
                    //the first loop needs to check for r or v
                    if (q === numericLf) {
                        // console.log('first is ' + q)
                        //this first loop, if has r, needs to add both , if is v, needs to add only that
                        if (/r/.test(Lf)) {
                            range.push(q + 'r')
                            range.push(q + 'v')
                        } else {
                            range.push(q + 'v')
                        }
                    }
                    
                    //the last loop needs to check for r or v
                    else if (q === (last -1)) {
                        //   console.log('last is ' + q)
                        if (q = numericLto) {
                            //this last loop, if has r, needs to add only that, if is v, needs to add both
                            if (/r/.test(Lto)) {
                                range.push(q + 'r')
                            } else {
                                range.push(q + 'r')
                                range.push(q + 'v')
                            }
                        }
                    } else {
                        // console.log('looping  ' + q)
                        range.push(q + 'r')
                        range.push(q + 'v')
                    }
                }
            }
            //target
            
            else if (Lta != '') {
                // there is one target
                range.push(Lta)
                // there are several targets
                // in that case there will be more objects in the results...
            }
            // there is only from, get to the end of the manuscript ?? for the moment simply push that one value (it will always be one)
            else if (Lto = '' && Lf != '') {
                // there is one target
                range.push(Lf)
                // there are several targets
                // in that case there will be more objects in the results...
            }
            
            // console.log(range)
            
            
            // intial logic for this part taken from http://jsfiddle.net/g7uY9/1/
            // https://stackoverflow.com/questions/21512260/merge-equal-table-cells-with-jquery
            
            //console.log(range.length)
            // for each row in the table with a folio = to one of the values in the range, add to the right column the name of the unit
            for (var p = 0; p < range.length; p++) {
                var value = range[p]
                //console.log(value + ' is the line we are looking for')
                for (var r = 0; r < table.length; r++) {
                    var fol = table[r].folio
                    if (fol == value) {
                        var matchingFolio = table[r]
                        //console.log(matchingFolio)
                        for (var prop in matchingFolio) {
                            //console.log(matchingFolio[prop])
                            //console.log(Type)
                            //console.log(name)
                            if (prop == Type) {
                                matchingFolio[prop] = name
                            }
                            //console.log(matchingFolio)
                        }
                    }
                }
            }
        });
        
        //console.log(table.length)
        for (var i = 0; i < table.length; i++) {
            tr = $('<tr/>');
            
            addColumn(tr, 'quire', i);
            addColumn(tr, 'folio', i);
            addColumn(tr, 'UniMat', i);
            addColumn(tr, 'UniMarq', i);
            addColumn(tr, 'UniCah', i);
            addColumn(tr, 'UniCont', i);
            addColumn(tr, 'addition', i);
            addColumn(tr, 'UniMain', i);
            addColumn(tr, 'UniEcri', i);
            addColumn(tr, 'UniRegl', i);
            addColumn(tr, 'UniMep', i);
            addColumn(tr, 'decoration', i);
            addColumn(tr, 'UniProd', i);
            $('#SdCTable tbody').append(tr);
        };
        
      $("#graphloadingstatus").text('making the table a bit more compact')
        $('#SdCTable tbody tr').each(
        function (row) {
             
            if (row > 0) {
                var thisrow = $(this)
                var previousrow = $(this).prev()
                if ((thisrow.children('td').eq(0).text() === previousrow.children('td').eq(0).text()) && (thisrow.children('td').eq(2).text() === previousrow.children('td').eq(2).text()) && (thisrow.children('td').eq(3).text() === previousrow.children('td').eq(3).text()) && (thisrow.children('td').eq(4).text() === previousrow.children('td').eq(4).text()) && (thisrow.children('td').eq(5).text() === previousrow.children('td').eq(5).text()) && (thisrow.children('td').eq(6).text() === previousrow.children('td').eq(6).text()) && (thisrow.children('td').eq(7).text() === previousrow.children('td').eq(7).text()) && (thisrow.children('td').eq(8).text() === previousrow.children('td').eq(8).text()) && (thisrow.children('td').eq(9).text() === previousrow.children('td').eq(9).text()) && (thisrow.children('td').eq(10).text() === previousrow.children('td').eq(10).text()) && (thisrow.children('td').eq(11).text() === previousrow.children('td').eq(11).text()) && (thisrow.children('td').eq(12).text() === previousrow.children('td').eq(12).text())) {
                    var rangeTo = thisrow.children('td').eq(1).text() // get the text of the cell in this row
                    var rFtext = previousrow.children('td').eq(1).text() // get the text of the same cell in the previous row
                    var rangeFrom = ''
                    if (/\s-\s/.test(rFtext)) {
                        rangeFrom = rFtext.substring(0, rFtext.indexOf(' -'))
                    } else {
                        rangeFrom = rFtext
                    }
                    var newRange = rangeFrom + ' - ' + rangeTo // build the new string
                    previousrow.children('td').eq(1).text(newRange) // substitute the content of the previous row
                    
                    var allpreviousrows = thisrow.prevAll()
                    
                    //as soon as one line is preserved, then the accounting on the previous row tds with rowspan will not work anymore,
                    // it will have to look all the way up line by line till it finds a td with a rowspan to decrease
                    
                    //  if(previousrow.children('td[rowspan]').length != 0){
                    // console.log('there are td[rowspan]')
                    var tds = thisrow.children('td')
                    var prevtds = previousrow.children('td')
                    // console.log(tds)
                    $(tds).each(
                    // loop trough each td in the current row and check if it is equal to the same cell in the previous row and if not do nothing, if yes then check if
                    // there is a rowspan in a previous line
                    function (rowspantd) {
                        
                        //console.log('looping through the tds of row ' + row)
                        // console.log(tds[rowspantd])
                        var td = tds[rowspantd]
                        var prevtd = prevtds[rowspantd]
                        //console.log(td)
                        //console.log(prevtd)
                        if ($(td).text() === $(prevtd).text()) {
                            //console.log('TD ' + rowspantd + 'has the same value as in the previous row')
                            $(allpreviousrows).each(function (allprevrows) {
                                //check if it has a rowspan
                                var thistdrowspan = $(this).children('td').eq(rowspantd)
                                if (thistdrowspan.attr('rowspan')) {
                                    var rowspanvalue = thistdrowspan.attr('rowspan')
                                    // console.log('previous row' + allprevrows + ' td ' + rowspantd + 'has value' + rowspanvalue)
                                    if (parseInt(rowspanvalue) === 1) {
                                        thistdrowspan.removeAttr('rowspan')
                                        // console.log('previous row' + allprevrows + ' td ' + rowspantd + ' had a rowspan=1, I have removed this attribute from td ' + rowspantd)
                                    } else {
                                        var newvalue = parseInt(rowspanvalue) - 1
                                        thistdrowspan.attr('rowspan', newvalue)
                                        // console.log('previous row' + allprevrows + ' td' + rowspantd + 'has NEW value' + newvalue)
                                    }
                                    return false;
                                }
                            })
                        } else {
                            //console.log('not the same as the same td in the previous line ')
                        }
                    })
                    //}
                    thisrow.remove() //remove this row since it is superfluous
                } else {
                    // console.log('row ' + row + ' is not equal to the previous')
                }
            } else {
                //  console.log('the first row')
            }
        });
        
        
      $("#graphloadingstatus").text('adding links')
       $('#SdCTable tbody tr td').each(function (tdindex) {
       //console.log('td')
            if ($(this).attr('style') === 'display:none') {
            } else {
                var txt = $(this).text()
               if (txt === '') {
                //console.log('empty')
                } else if (/\d+[rv]/.test(txt)) {
                
               // console.log(txt + 'images')
                    //link to images
                   // if (/-/.test(txt)){var splitxt=  txt.split(" - ")  
                    //images range
                   // }
                    //else {
                    //single image
                    // IT IS NOT POSSIBLE AT THE MOMENT TO LINK TO IMAGES FROM HERE, DUE TO THE LACK IN THE RDF AND RESULT OF THE QUERY OF THE DATA STORED IN locus/@facs
                 // storing this Info in the RDF would be useless, as it is not always there.
                 /* var tile =''
                    var openseaID = 'openseadragon'+tdindex
                    var modalID = 'images'+tdindex
                    var link = '<a href="#'+txt+'" data-toggle="modal" data-target="'+modalID+'">'+txt+'</a>'
                    var modal = '<div class="modal fade" id="'+modalID+'" \
                    role="dialog" style="display: none;" aria-hidden="true">\
                      <div class="modal-dialog">\
                        <div class="modal-content">\
                     <div class="modal-header">\
                        <button type="button" class="close" data-dismiss="modal">Close</button>\
                          <h4 class="modal-title">Images from '+manifest+'</h4></div>\
                          <div class="modal-body">\
                        <div id="'+openseaID+'"><script type="text/javascript">\
                           OpenSeadragon({\
                           id: "'+openseaID+'",\
                           prefixUrl: "../resources/openseadragon/images/",\
                           preserveViewport: true,\
                           visibilityRatio:    1,\
                           minZoomLevel:       1,\
                           defaultZoomLevel:   1,\
                           tileSources:   ["'+tile+'" ]\
                           });\
                        </script></div><div class="modal-footer">\
                        <button type="button" class="btn btn-default" data-dismiss="modal">Close</button></div>\
                                                                                    </div></div></div>'*/
                  //  }
                  
                } else {
              var splitxt=  txt.split(" ")
              var l = splitxt.length
              //console.log(l)
              var last = l-1
                    var finalid = splitxt[last]
                   // console.log(finalid)
                    var name = splitxt[1] + ' ' + splitxt[2]
                    // console.log(name)
                    var newtext = '<a class="enrichable"  data-anchor="' + finalid + '" target="_blank" href="/manuscripts/' + id + '/main#' + finalid + '">' + name + '<a/>'
                    $(this).html(newtext)
                }
            }
        });
        
        function addColumn(tr, column, i) {
            var row = table[i],
            prevRow = table[i - 1],
            td = $('<td>' + row[column] + '</td>');
            if (prevRow && row[column] === prevRow[column]) {
                td.hide();
            } else {
                var rowspan = 1;
                for (var j = i; j < table.length - 1; j++) {
                    if (table[j][column] === table[j + 1][column]) {
                        rowspan++;
                    } else {
                        break;
                    }
                }
                td.attr('rowspan', rowspan);
            }
            
            tr.append(td);
        };
        
      $("#graphloadingstatus").remove()
      $('#enrichTable').removeAttr('disabled');
    });
    
    
});

$("#enrichTable").on('click', function(){
/*console.log('clicked enrich')*/
 var id = $('#SdCTable').data('id')
     $('.enrichable').each(function(){
      var anchor = $(this).data('anchor')
/*     console.log(anchor)*/
     var apicallenrich = '/api/enrichMe/'+id+'/' +anchor
/*    console.log(apicallenrich)*/
var el = $(this)
    $.getJSON(apicallenrich, function (data) {
/*    console.log(data)*/
    var enrichment = $('<table class="table enriched"><tbody></tbody></table>')
    for(var item in data){
            var row = "<tr><td><b>" + item + "</b></td><td>" + data[item] + "</td></tr>";
            enrichment.append(row)
        }
     $(el).after(enrichment) 
    });
      }
     );
});
