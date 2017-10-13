$('#persRole').change(function (showthefilters) {
    var role = $('#persRole').val()
    var apiurl = '/api/hasrole/'
    $.getJSON(apiurl + role, function (data) {
        var items =[];
        var heading = '';
        if (data.total == 0) {
           heading = "<h4>There are no persons with role <span class='label label-warning'>" + data.role + "</span></h4>";
           $("#persWithRoleResults").empty();
           $(heading).appendTo("#persWithRoleResults");
            
        } 
        
        else if (data.total > 0) { 
        heading =  "<h4>There are <span class='label label-success'>" + data.total + "</span> persons with a role <span class='label label-info'>" + data.role + "</span></h4>"
        for (var i = 0; i < data.hits.length; i++) {
                var match = data.hits[i]
                var id = match.pwl;
                var title = match.title;
                var context =[];
                if (match.hasthisrole.length > 0) {
                    var text =[];
                    var Titles =[];
                    $.each(match.hasthisrole, function (i, val) {
                        
                        text.push("<a href='/" + val.source + "'>" + val.sourceTitle + "</a>")
                    })
                    
                    
                    
                    context.push(text.join('<br/>'))
                } else {
                    context.push("<a href='/" + match.hasthisrole.source + "'>" + match.hasthisrole.sourceTitle + "</a>")
                }
                items.push("<div class='card'><div id='" + id + "' class='card-block'><h4 class='card-title'><a href='/" + id + "'>" + title + "</a></h4><p class='card-text'> is " + role + " of:</p><div class='card-text'>" + context + "</div></div></div>");
            }
            $("#persWithRoleResults").empty();
            $(heading).appendTo("#persWithRoleResults");
            $("<div/>", {
                addClass: 'card-columns',
                html: items.join("")
            }).appendTo("#persWithRoleResults");
        };
    });
});

$(document).on({
    ajaxStart: function () {
        $("img#loading").show();
    },
    ajaxStop: function () {
        $("img#loading").hide();
    }
});