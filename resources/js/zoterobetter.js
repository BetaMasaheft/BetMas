$(document).ready(function () {
    $('#textinput').on("change", function () {
        var tag = this.value;
        
        var apiurl = "https://api.zotero.org/groups/358366/items?&tag="; // this is the base for all calls here.
        console.log(apiurl);
        $.getJSON(apiurl + tag, function (data) {
            console.log(data);
            
            if (data.length === 0) {
                // if the response is an empty array (that is what comes from a correct api call with the wrong tag then alert the user/editor
                alert('Something is wrong with bibliographic reference to ' + tag + '.  Perhaps it does not exist or the id contains a typo. Please, go check the source file and the Zotero Group library to fix this.  ')
            } else {
                console.log('ok')
                // check again the class, if there is Zotero-full print with the HCLES style
                var fullnames =[];
                var fulleditors =[];
                var fullcontributors =[];
                var names =[];
                var editors =[];
                var contributors =[];
                var fullcit = "";
                var citation = "";
                $.each(data[ "0"].data.creators, function (i, item) {
                    // for each creator in the Zotero data store the lastName in the variable
                    if (item.creatorType == 'author') {
                        //if the name is one, then use that
                        if (item.name) {
                            var onename = item.name
                            names.push(onename)
                            var onenobj = {
                                'sur': onename
                            }
                            fullnames.push(onenobj)
                        } else {
                            // otherways split first and last name and make them into an object where the first name is only the initial
                            var surname = item.lastName
                            var firstname = item.firstName
                            var fn = firstname.charAt(0).toUpperCase() + '.'
                            var nobj = {
                                'sur': surname, 'n': fn
                            }
                            var NAME = surname + ', ' + fn
                            names.push(surname)
                            fullnames.push(nobj)
                        }
                        console.log(fullnames)
                    } else {
                        if (item.creatorType == 'editor') {
                            var surname = item.lastName
                            
                            var firstname = item.firstName
                            var NAME = surname + ', ' + firstname.charAt(0).toUpperCase() + '.'
                            editors.push(surname)
                            fulleditors.push(NAME)
                        } else {
                            if (item.creatorType == 'contributor') {
                                var surname = item.lastName
                                
                                var firstname = item.firstName
                                var NAME = surname + ', ' + firstname.charAt(0).toUpperCase() + '.'
                                contributors.push(surname)
                                fullcontributors.push(NAME)
                            } else {
                                names.push('no Author or Editor')
                            }
                        }
                    }
                });
                if (names.length == 0) {
                    // decide on the type and number of editors authors. if there are no authors, then deal with editors.
                    if (editors.length == 2) {
                        citation += editors.join(' and ') + ' '
                        fullcit += fulleditors[0].sur + ' ' + fulleditors[0].n + ' and ' + fulleditors[1].n + ' ' + fulleditors[1].sur
                    } else {
                        citation += editors.join(', ') + ' '
                        fullcit += fulleditors.join(', ') + ' '
                    }
                } else if (names.length == 2) {
                    
                    // otherways there are authors, if they are two join with and if more then ,
                    citation += names.join(', ')
                    var fulns =[]; //contains the series of names with surname and capital of first name, where only the first starts with surname.
                    var fnl = fullnames.length
                    for (var i = 0; i < fnl; i++) {
                        /*                   fulns.push(fullnames[i].sur + ' ' + fullnames[i].n)*/
                        if (i === 0) {
                            var surN = fullnames[i].sur + ', ' + fullnames[i].n
                            fulns.push(surN)
                        } else {
                            var Nsur = fullnames[i].n + ' ' + fullnames[i].sur
                            fulns.push(Nsur)
                        }
                    };
                    fullcit += fulns[0] + ' and ' + fulns[1]
                } else {
                var fulns =[]; //contains the series of names with surname and capital of first name, where only the first starts with surname.
                    var fnl = fullnames.length
                    for (var i = 0; i < fnl; i++) {
                        /*                   fulns.push(fullnames[i].sur + ' ' + fullnames[i].n)*/
                        if (i === 0) {
                            var surN = fullnames[i].sur + ', ' 
                            if(fullnames[i].n){surN += fullnames[i].n} 
                            fulns.push(surN)
                        } else {
                            var Nsur = ''
                            if(fullnames[i].n){Nsur += fullnames[i].n + ' '} 
Nsur += fullnames[i].sur + ' '
                            fulns.push(Nsur)
                        }
                    };
                    citation += names.join(', ') + ' '
                    fullcit += fulns.join(', ') + ' '
                }
                var title = data[ "0"].data.title;
                var DATE = data[ "0"].data.date
                var extra = data[ "0"].data.extra
                var dformat = ''
                if (DATE.includes('-')) {
                    dformat += DATE.replace('-', '–')
                } else {
                    dformat += DATE
                }
                var CE = ''
                var ecdate = ''
                
                var pubdate = ''
                if (extra.includes('EC')) {
                    ecdate += extra + ' = '; CE += ' CE'
                }
                if (extra.includes('pub')) {
                    pubdate += ', ' + extra
                    console.log(pubdate)
                   }
                if (data[ "0"].data.itemType == 'journalArticle') {
                    var pubtitle = data[ "0"].data.publicationTitle;
                    var vol = data[ "0"].data.volume
                    var pages = data[ "0"].data.pages
                    var pformat = ''
                    if (pages.includes('-')) {
                        pformat += pages.replace('-', '–')
                    } else {
                        pformat += pages
                    }
                    fullcit += ' ' + dformat + '. ‘' + title + '’, <i>' + pubtitle + '</i>, ' + vol + ' (' + dformat + CE + pubdate + '), ' + pformat + '.'
                } else if (data[ "0"].data.itemType == 'book') {
                    var place = data[ "0"].data.place
                    var publisher = data[ "0"].data.publisher
                    fullcit += ' ' + dformat + '. <i>' + title + '</i> (' + place + ': ' + publisher + ', ' + ecdate + dformat + CE + pubdate + ').'
                }
                citation += ' ' + dformat // add date
                
 var style = "&format=bib&style=hiob-ludolf-centre-for-ethiopian-studies"
 var call = apiurl + tag + style
 console.log(call)
                $.get(call, function (citation) {
                        var text = $(citation).find("div.csl-entry").html();
                        
$("#HLCES").html(text);                     
});
                
                
                $("#cit").html(citation);
                $("#result").html(fullcit);
                //console.log(data[ "0"].data);
            };
        });
    });
});
function capitalizeFirstLetter(string) {
    return string.charAt(0).toUpperCase() + string.slice(1);
}