
$("a[id$='relations']").each(function () {
    var id = this.id;
    var trimmedID = id.substring((id.indexOf('Ent') + 3), id.indexOf('relations'));
    var el = this;
    var content = $('#' + trimmedID + 'relations-content');
    
    $(el).popover({
        html: true, content: content, title: 'What Points Here', delay: {
            show: 500,
            hide: 100
        }
    });
    $(el).click(function () {
        
        setTimeout(function () {
            $('.popover').fadeOut('slow');
        }, 5000);

    });
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