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

/*<div><a class="w3-button msitemloader" data-mainid="ESqdq004" data-msitem="ms_i1-1-2">Click here to load the 3 contained in the current one.</a><div id="msitemloadcontainerms_i1-1-2"></div></div>*/

function loadMsItems(mainid, msitemid, start) {
    var limit = 10;
    var msContainer = '#msitemloadcontainer' + msitemid;
    $(msContainer).find('.msitemloader').remove();

    var apiCall = '/api/loadmsItems/' + mainid + '/' + msitemid + '?start=' + start + '&limit=' + limit;

    $.getJSON(apiCall, function (data) {
        if (data.msitems.length === 0) {
            if (start > 1 && $(msContainer).find('.no-more-items-msg').length === 0) {
                $(msContainer).append('<div class="w3-text-grey no-more-items-msg" style="margin:0.5em 0;">No more items.</div>');
            }
            return;
        }
        $(msContainer).append(data.msitems.join(''));
        if(data.hasMore) {
            var loadMoreBtn =
                '<a class="w3-button msitemloader w3-yellow" ' +
                'data-mainid="' + mainid + '" data-msitem="' + msitemid + '" data-start="'+ (start+limit) +'">' +
                'Load more items...</a>';
            $(msContainer).append(loadMoreBtn);
        }

    });
}

$(document)
.off('click', '.msitemloader')
.on('click', '.msitemloader', function (e) {
  e.preventDefault();
    var $btn = $(this);
    var mainid  = $btn.data('mainid');
    var msitemid = $btn.data('msitem');
    var start   = $btn.data('start') || 1;
    loadMsItems(mainid, msitemid, start);
  });
  
 