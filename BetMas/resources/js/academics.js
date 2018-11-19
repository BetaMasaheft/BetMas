$(document).on('ready', function () {

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