
$(document).on('ready', function () {

$.getJSON('/api/latest', function(data){
    var latest = $('#latest')
    var length = data.length
    for (i = 0; i < length; i++) { 
    $(latest).append('<li><a href="'+data[i].id+'">'+data[i].title+'</a>: on '+data[i].when+', '+data[i].who+' ['+data[i].what+']</li>')
    }
});

/*(:displaies on the hompage the totals of the portal:)*/
$.getJSON('/api/count', function(data){
    var count = $('#count')
    var total = data.total
    var tms = data.totalMS
    var tp = data.totalPersons
    var tw = data.totalWorks
    var ti = data.totalInstitutions
    var diff = total - (tms + tp + tw + ti)
    $(count).append('<p>There are <b class="lead">'+total+'</b> searchable and browsable items in the app. </p>')
    $(count).append("<p><b  class='lead'>"+ti+"</b> are Repositories holding Ethiopian Manuscripts. </p>")
    $(count).append("<p><b  class='lead'>"+tms+"</b> are Manuscript's Catalogue Records.  </p>")
    $(count).append("<p><b  class='lead'>"+tw+"</b> are Text units, Narrative units or literary works.</p>")
    $(count).append("<p><b  class='lead'>"+tp+"</b> are Records about people, groups, ethnic or linguistic groups. </p>")
    $(count).append("<p>The other " +diff+" records are Authority files and places which are not repositories. </p>")
    
});

$.getJSON('/api/academics', function(data){
    var acs = $('#academicscards')
    var length = data.length
    
    for (i = 0; i < length; i++) {
    var id = data[i].id
var tit = data[i].title
var txt = data[i].text
var dd = data[i].dates
var bio = data[i].bio
var zot = data[i].zoturl
var wd = data[i].wd

    $(acs).append('<div class="card"><div class="card-block"><h4 class="card-title"><a href="/'+id+'" target="_blank">'+tit+'</a></h4><p class="card-text">'+txt+'</p><p class="card-text"><small class="text-muted">'+dd+'</small></p><p class="card-text academicBio">'+bio+'</p><p class="card-text"><a  href="'+zot+'" target="_blank">Items in Zotero EthioStudies</a></p><p class="card-text">'+wd+'</p></div></div>')
    }
    });

});