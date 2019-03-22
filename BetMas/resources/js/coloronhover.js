$('a.itemtitle').hover(function () {
    
    var id = $(this).data('value');
    //     console.log(id);
    $(this).addClass("selected");
    $("a[data-value='" + id + "']:not(.selected)").each(function () {
        var sameid = $(this).data('value');
        $(this).addClass("alsoHere");
       setTimeout(function(){
            $('a').removeClass("alsoHere");
    }, 3000);
        //        console.log('I am also here!' + sameid)
    });
    setTimeout(function(){
            $('a.selected').removeClass("selected");
    }, 3000);
});

