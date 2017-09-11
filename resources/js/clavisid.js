$("a[id^='clavis']").each(function () {
    var id = this.id;
    var trimmedID = id.substr((id.indexOf('clavis') + 6));
    var el = this;
    var apiurl = '/api/clavis/'
    $.getJSON(apiurl + trimmedID, function (data) {
        
        var content = ""
        for (var i = 0; i < data.clavis.length; i++) {
            content.push(data.clavis[i])
            console.log(content)
        };
        
        $(el).popover({
            html: true, content: content, title: 'This Work in other Clavis', placement: 'right'
        })
    });
});
