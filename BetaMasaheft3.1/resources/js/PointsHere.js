
$("a[id$='relations']").on('click', function () {
    var el = this;
/*    check if there is already a popover*/
    if ($(this).next().hasClass('popover')) {
      //  console.log('there is already a popover here, I load it');
        $(el).popover()
    } else {
/*    there is no popover, lets make one*/
        var id = this.id;
/*get the item id from the complex id (legacy...)*/
var trimmedID = id.substring((id.indexOf('Ent') + 3), id.indexOf('relations'));
/*make a temporary popup, in case the request takes sometime (the loader image will also fire)*/
        $(el).popover({
            html: true,
            title: 'What Points Here',
            content: 'Loading info...'
        });
/*        make the query to the api */
        var callsparql = '/api/SPARQL/relations/' + trimmedID
/*        disable the button*/
        $(el).attr("disabled", "disabled");
        $.getJSON(callsparql, function (data) {
            //console.log(data)
/*            if there are no contents, data.info will be there, then destroy the temporary popover and make one saying so.*/
            if (data.info) {
                $(el).removeAttr("disabled");
                $(el).popover('destroy');
                $(el).popover({
                    html: true,
                    title: 'What Points Here',
                    content: data.info
                });
            } else {
            
/*            if there are results,  destroy the temporary popover and make one with the contents.*/
                $(el).removeAttr("disabled");
                var content = $('<div id="' + trimmedID + 'relations-content"><ul xmlns="http://www.w3.org/1999/xhtml" class="nodot"><head xmlns="http://www.w3.org/1999/xhtml" >This record, with ID: ' + trimmedID + ' is linked to </head></div>');
                var length = data.length
                
                $(data).each(function(i){
                    $(content).append('<li><a target="_blank" href="' + this.id + '">' + this.title + '</a> by ' + this.relation + '</li>')
                })
                
                $(el).popover('destroy');
                $(el).popover({
                    html: true,
                    title: 'What Points Here',
                    content: content
                });
            }
        });
        /*    tecnique copied from https://www.raymondcamden.com/2015/04/03/strategies-for-dealing-with-multiple-ajax-calls/*/
    }
});

$("a[id^='date']").each(function () {
    var id = this.id;
    var trimmedID = id.substring((id.indexOf('date') + 4), id.indexOf('calendar'));
    var el = this;
    var content = $('#dateInfo' + trimmedID);
    
    $(el).popover({
        html: true, content: content, title: 'About this date', placement: 'top'
    })
});