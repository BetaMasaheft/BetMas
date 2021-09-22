
$(document).on('ready', function () {


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


});