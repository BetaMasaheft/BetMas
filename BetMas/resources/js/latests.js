$(document).on('ready', function () {

$.getJSON('/api/latest', function(data){
    var latest = $('#latest')
    var length = data.length
    for (i = 0; i < length; i++) { 
    $(latest).append('<li><a href="'+data[i].id+'">'+data[i].title+'</a>: on '+data[i].when+', '+data[i].who+' ['+data[i].what+']</li>')
    }
});

});