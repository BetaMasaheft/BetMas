$('#persRole').change(function (showthefilters) {
    var role = $('#persRole').val()
    var apiurl = '/api/hasrole/'
    $.getJSON(apiurl + role, function (data) {
        var items =[];
        var heading = '';
        if (data.total == 0) {
           heading = "<h4>There are no persons with role <span class='w3-tag w3-gray w3-round'>" + data.role + "</span></h4>";
           $("#persWithRoleResults").empty();
           $(heading).appendTo("#persWithRoleResults");
            
        } 
        
        else if (data.total > 0) { 
        heading =  "<h4>There are <span class='w3-tag w3-red w3-round'>" + data.total + "</span> persons with a role <span class='w3-tag w3-gray w3-round'>" + data.role + "</span></h4>"
        for (var i = 0; i < data.hits.length; i++) {
                var match = data.hits[i]
                var id = match.pwl;
                var title = match.title;
               
                items.push("<div class='w3-card-4 w3-padding w3-margin w3-third'><div id='" + 
                id + "' class='w3-display-container'><header class='w3-container'><a href='/" + 
                id + "'>" + title + "</a></header><div class='w3-container'> is mentioned as " + 
                role + " "+match.hits
                +" times:</div><button class='w3-button w3-gray w3-small roleid' data-personid='" + 
                id + "' data-role='" + role +
                "'>Click to see in which records.</button><div class='w3-container' id='"+ 
                id + "itemlist'></div></div></div>");
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

$(document).on('click', ".roleid", function () {
    var el = this
        var person = $(this).data('personid');
        var role = $(this).data('role');
        console.log(role)
        console.log(person)
        
        var hasRole = "/api/hasrole/" + role + '/' + person 
        console.log(hasRole)
        
        $.getJSON(hasRole, function (data) {
            var results = data.hasthisrole
            console.log(data)
            console.log(results)
            var length = results.length
            console.log(length)
            var list = $('#'+person+'itemlist')
            for (i = 0; i < length; i++) {
                    $(list).append('<a target="_blank" href="/' + results[i].prov + '">' + results[i].sourceTitle + '</a><br/>')
                }

        });
   
});