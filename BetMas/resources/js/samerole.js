$(document).on({
    ajaxStart: function () {
        $("img#loadingRole").show();
    },
    ajaxStop: function () {
        $("img#loadingRole").hide();
    }
});

$(".AttestationsWithSameRole").on('click', function () {
    var el = this
        var role = $(this).data('value');
    var hasRole = "/api/RoleAttestations?role=" + role
    
    $.ajax(hasRole, {
            success: function (data) {
                $("#roleAttestations").append(data);
               printTitle() 
               $('.MainTitle').removeClass('MainTitle')
            }
        });
        
});


$(".role").on('click', function () {
    var el = this
     var role = $(this).text();
     
        var hasRole = "/api/hasrole/" + role  
        $.getJSON(hasRole, function (data) {
            var results = data.hits 
            var length = results.length
            console.log(length)
            $('#'+role+'listcount').text('There are other ' +  data.total + ' ' + role + 's');
            var list = $('#'+role+'listitems')
            for (i = 0; i < length; i++) {
                    $(list).append('<li><a target="_blank" href="/' + results[i].pwl + '">' + results[i].title + '</a><button class="btn btn-primary btn-xs roleid" data-personid="' + results[i].pwl + '" data-role="' + role + '"> is mentioned as '+role+' '+ results[i].hits+' times. Click to see which.</button><ul id="' + results[i].pwl + 'itemlist"></ul></li>')
                }

        });
   
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
                    $(list).append('<li><a target="_blank" href="/' + results[i].prov + '">' + results[i].sourceTitle + '</a></li>')
                }

        });
   
});