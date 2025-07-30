function callformpart(file, id) {
    
    // check first that the element is not there already
    var myElem = document.getElementById(id);
    // if it is not there, load it
    if (myElem === null) {
        $.ajax(file, {
            success: function (data) {
                $("#searchForm").append(data);
            }
        });
    }
    // else it has already been loaded, therefore simply show it.
    var jid = '#' + id
    $(jid).toggle();
};

$("#erweitertesuche").one("click", function () {
    callformpart('as.html', 'erweiterte');
});

$("#erweitertesuche").click(function () {
    $('.erweit').toggle("slow");
});

$(document).ready(function () {
    
    $("a.reference").on("click", function () {
        var el = this;
        var reference = $(this).data('value')
        var splitref = reference.split("/");
        var sourceReference = $(this).data('ref')
        var bmid = $(this).data('bmid')
        var apiDTS = '/api/dts/text/'
        var result = ""
        
        $.getJSON(apiDTS + reference, function (data) {
            var id = data[ "0"].id
            var cit = data[ "0"].citation
            var title = data[ "0"].title
            var text = data[ "0"].text
            if (data[ "0"].info) { result += '<p>There is no text yet for this passage in Beta maṣāḥǝft.</p><a target="_blank" href="/works/' + bmid + '">See Work record</a>'
            } else {
                result += '<p>Text of ' + cit + ' .</p><p>' + text + '</p><a target="_blank" href="/works/' + bmid + '/text?start=' + splitref[1] + '">See full text</a>'
            }
            $(el).popover({
                html: true,
                content: result,
                title: 'Text Passage'
            });
        })
    })
    
    var lemma = ''
    var lem = $('#lemma').text()
    //console.log(lem)
    // this assumes a case exactely like "ሲኖዶስ et ሴኖዶስ" and that the kwic search rest function will read the white space as OR
    if (/et/i.test(lem)) {
        var split = lem.split(' ');
        lemma = split[0] + ' ' + split[2]
    } else {
        lemma = $('#lemma').text()
    }
    //console.log(lemma)
    var apiurl = '/api/kwicsearch?element=ab&element=title&element=q&element=p&element=l&element=incipit&element=explicit&element=colophon&element=summary&element=persName&element=placeName&q='
    
    var call = apiurl + lemma
    //console.log(call)
    
    $('#lemma').append('፡')
    $('.navlemma').append('፡')
    $.getJSON(call, function (data) {
        //console.log(data)
        
        var items =[];
        
        if (data.total > 1) {
            
            $('#NumOfAtt').text(data.total + ' records contain ');
            for (var i = 0; i < data.items.length; i++) {
                
                var match = data.items[i];
                
                var view = match.text;
                
                var id = match.id;
                
                
                var coll = match.collection;
                
                var title = match.title
                
                var parsedtext = '';
                
                if (match.hitsCount > 1) {
                    var text =[];
                    $.each(match.results, function (i, val) {
                        text.push(val)
                    })
                    parsedtext += text.join(' ')
                } else {
                    parsedtext += match.results
                }
                items.push("<div class='card'><div id='" + id + "' class='card-block'><div class='card-title'><a target='_blank' href='/" + coll + '/' + id + "/" + view + "?hi=" + lemma + '&start=' + match.textpart + "'>" + title + "</a> <span class='badge'>" + match.hitsCount + "</span></div><div class='card-text'><p>" + parsedtext + "</p></div></div></div>");
            }
            $("<div/>", {
                addClass: 'card-columns',
                html: items.join("")
            }).appendTo("#attestations");
        } else {
            
            if (data.total == 1) {
                var match = data.items
                
                var id = match.id;
                
                var coll = match.collection;
                
                var title = match.title
                
                var parsedtext = '';
                
                if (match.hitsCount > 1) {
                    var text =[];
                    $.each(match.results, function (i, val) {
                        text.push(val)
                    })
                    parsedtext += text.join(' ')
                } else {
                    parsedtext += match.results
                }
                var url = "/" + coll + '/' + id + "/main?hi=" + encodeURIComponent(lemma)
                items.push('<div class="row"><div id="' + id + '" class="card"><div class="col-md-3"><div class="col-md-10"><a href="' + url + '">' + title + "</a></div><div class='col-md-2'><span class='badge'>" + match.hitsCount + "</span></div></div><div class='col-md-9'><p>" + parsedtext + "</p></div></div></div>");
                
                
                $("<div/>", {
                    html: items.join("")
                }).appendTo("#attestations");
            } else {
                
                $("<div/>", {
                    html: 'no attestations of ' + lemma + ' exactly'
                }).appendTo("#attestations");
            }
        }
    });
});
