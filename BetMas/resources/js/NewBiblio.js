$.ajaxSetup({ cache: false });
$(document).on('ready', function () {
    checkforbiblio();
});


function checkforbiblio() {
    if ($('.Zotero')) {
        printbibl();
    } else {
        setTimeout(printbibl, 50);
    }
};

function printbibl() {
    //check all bibl records, they are in the served page <a class="Zotero Zotero-full" data-value="bm:Migne1857Athanasii" data-unit="page" data-range="2-5">bm:Basset1893Tomar</a>
    $(".Zotero").each(function () {
        var el = this
        //do the following on each of them. This could be optimized, as there are several times the same citations and it could save time to load the Zotero data once and for all.
        var P = $(this).parent();
        // the parent of the node with the .Zotero
        var tag = $(this).data('value');
        // the bm:tag identifying the citation
        
        
        
        var apiurl = "https://api.zotero.org/groups/358366/items?&tag="; // this is the base for all calls here.
        $.getJSON(apiurl + tag, function (d) {
            // this call is for the generic JSON standard output from Zotero.
           // console.log(apiurl + tag)
          // console.log(d)
            var url = ''; // a variable to store the link to the url
            var thisurl = d[ "0"].data.url; // the url in the zotero
            if (thisurl == '') {
                // if there is a url to a resource print that, otherways link to Zotero
                url += ' <a target="_blank" href="https://www.zotero.org/groups/ethiostudies/items/tag/' + tag + '"><span class="glyphicon glyphicon-share" style="display:inline;"/></a>'
            } else {
                url += ' <a  target="_blank" href="' + thisurl + '""><span class="glyphicon glyphicon-share" style="display:inline;"/></a>'
            };
            //console.log(url);
            if (d.length === 0) {
                // if the response is an empty array (that is what comes from a correct api call with the wrong tag then alert the user/editor
                alert('Something is wrong with bibliographic reference to ' + tag + '.  Perhaps it does not exist or the id contains a typo. Please, go check the source file and the Zotero Group library to fix this.  The element giving this error is contained in ' + P[0].nodeName.toLowerCase() + '#' + P[0].id)
            } else {
                //console.log('ok')
                // check again the class, if there is Zotero-full print with the HCLES style
                if ($(el).hasClass("Zotero-full")) {
                    
                    var style = "&format=bib&locale=en-GB&style=hiob-ludolf-centre-for-ethiopian-studies"; // the HCLES  Zotero Style
                    
                    var fullcitation = "";
                    
                    var call = apiurl + tag + style // this call to the Zotero API returns the formatted citation into a div
                    
                    $.get(call, function (citation) {
                        var text = $(citation).find("div.csl-entry").html();
                        // store only the inner div's html (i.e. keep italict what is italics)
                         // console.log(call)
                        var unit = $(el).data('unit');
                        //the unit of the range
                        
                        
                        var range = $(el).data('range');
                        // the range
                        
                        citationrange = '';
                        if ( $(el).attr('data-range')) {
                        if(/\s/.test($(el).attr('data-range'))){
/*                            more then one value for citation range*/
                             var citationRanges = []
                        var split = unit.split(" ")
                        var splitrange = range.split(" ")
                        var splitsize = split.length
                        for (i = 0; i < splitsize; i++) {
                        citationRanges.push( split[i] + ' ' + splitrange[i])
                        }
                            citationrange += ', ' + citationRanges.join( ', ')
                        } else{
/*                       only one citation range*/
                            citationrange += ', ' + unit + ' ' + range
                            }
                        } else {
                        };
                        // console.log('this is the citation range ' + citationrange)
                        var fullcitation = text.slice(0, -1) + url + citationrange + '.' // the content of the Zotero formatted response has a full stop, which needs to be removed to allow for the citedRange to be added
                        $(el).html(fullcitation) // add the html formatted full bibliography where needed
                    });
                } else {
                    // if it is not Zotero-full it is Zotero-citation, then print the citation. Author YEAR, RANGE
                    // console.log(tag)
                    var bareurl = "https://www.zotero.org/groups/ethiostudies/items/tag/" + tag
                    
                    $(el).attr("href", bareurl);
                    //add the url to the element directly
                    var ZotCitparam = '&include=citation&style=hiob-ludolf-centre-for-ethiopian-studies'
                   
                      
                        
                    $.getJSON(apiurl + tag + ZotCitparam, function (d) {
                    
                    var unit = $(el).data('unit');
                        //the unit of the range
                        
                        
                        var range = $(el).data('range');
                        // the range
                        
                        citationrange = '';
                        if ( $(el).attr('data-range')) {
                            citationrange += ', ' + unit + ' ' + range
                        } else {
                        };
                        
                    
                        //console.log(d["0"].citation)
                      
                    $(el).html(d["0"].citation + citationrange);
                    //console.log(data[ "0"].data);
                   
                   });
                    
                  
                    
                   
                };
            }
        });
    });
};