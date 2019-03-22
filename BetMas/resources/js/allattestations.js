var attestations = $('<div/>')

$('#showattestations').on('click', function () {
    var type = $(this).data('value')
    var id = $(this).data('id')
    var apicall = '/api/attestations/' + type + '/' + id
    $.getJSON(apicall, function (data) {
    if(data.results == null) { $('#allattestations').append('No attestations of this entity could be found.')}
    else {
     var resheading = '<div class="w3-row"><div class="w3-quarter">Attestation source</div><div class="w3-threequarter">attestations</div></div>'
     var totatt = ''
     if (data.results.length > 1) {totatt = data.results.length} else {totatt = 1}
   var report = 'There are <span class="w3-label w3-red">' + totatt + '</span> entities with attestations of this record.'
   $('#allattestations').append(report)
         $('#allattestations').append(resheading)

        if (data.results.length > 1) {
            var resultlength = data.results.length
            for (var i = 0; i < resultlength; i++) {
                var res = data.results[i]
                results(res)
            }
        } else {

            results(data.results)
        }
       }
    })
    $(this).prop('disabled',true);
});

function results(res) {
    var allresults = ''
    var resid = res.id
    var restitle = res.title
    if (res.result.length > 1) {
        var reslength = res.result.length
        for (var l = 0; l < reslength; l++) {
            var thisresult = res.result[l]
            var thisentry = entry(thisresult)
            allresults += thisentry
        }
    } else {
        var thisresult = res.result
        var thisentry = entry(thisresult)
        allresults += thisentry
    }

    var resultdiv = '<div class="w3-panel w3-card-4 attestationresult "><div class="w3-quarter"><a href="/' + resid + '">' + restitle + '</a></div><div class="w3-threequarter">' + allresults + '</div></div>'
    $('#allattestations').append(resultdiv)
};

function entry(entry) {

    var entrytitle = entry.text
    var entryelem = entry.element
    var entrydate = entry.date
    var entryrole = entry.role
    var entrytitles = entry.jointitles
    var alloccurrences = ""

    if (entry.occurrences == null) {
    } else {
        if (entry.occurrences.length > 1) {
            var occlength = entry.occurrences.length
            for (var o = 0; o < occlength; o++) {
                var occ = entry.occurrences[o]
                var occs = occurrences(occ)
                alloccurrences += occs
            }
        } else {
            var occ = entry.occurrences
            var occs = occurrences(occ)
            alloccurrences += occs
        }
    }


    var thisentry = '<div class="w3-row singleattestation"><div class="w3-quarter">'+entry.position+ ') '+ entrytitles + '<b>'+ entrytitle + '</b>' + ' (' + entrydate + '), ' + entryrole + '['+entryelem+']</div><div class="w3-threequarter">' + alloccurrences + '</div></div><hr/>'
    return thisentry
};

function occurrences(occ) {
    var type = occ.type
    var path = eval('occ.' + type)
    var allnames = ""
    if (path.length > 1) {
        var pathlength = path.length
        for (var o = 0; o < pathlength; o++) {
            var name = path[o]
            var line = lines(name)
            allnames += line
        }
    } else {
        var name = path
        var line = lines(name)
        allnames += line
    }
    var alloccs = '<div class="w3-row w3-margin  w3-card-4"><p class="w3-padding">In the same context of this attestation also the following ' + type + ' occur</p><div class="w3-responsive"><table class="w3-table w3-hoverable"><thead><tr><th>name</th><th>type</th></tr></thead><tbody>' + allnames + '</tbody></table></div></div>'
    return alloccs
};


function lines(name) {

    var link = ''
    if (name.id == 'no-id') {
         link = name.name
    } else {
     link = '<a href="' + name.id + '">' + name.name + '</a>'

    }
    var typ = ''
    if (name.type == null) {
    } else {
        typ = name.type
    }
    var line = '<tr><td>' + link + '</td><td>' + typ + '</td></tr>'
    return line
};
