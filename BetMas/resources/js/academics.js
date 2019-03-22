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

    $(acs).append('<div class="w3-card-4 w3-padding w3-margin"><div class="w3-container"><header class="w3-container"><a href="/'+id+'" target="_blank">'+tit+'</a></header><p>'+txt+'</p><p><small class="text-muted">'+dd+'</small></p><p class="academicBio">'+bio+'</p><p><a  href="'+zot+'" target="_blank">Items in Zotero EthioStudies</a></p><p>'+wd+'</p></div></div>')
    }
    });
    
    });