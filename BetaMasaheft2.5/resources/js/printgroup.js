$('.printgroup').on('click', function(){
    var ids = []
    
    $('input.pdf').each(function() {
    if($(this).is(':checked')){ids.push($(this).data('value'))} 
    });
console.log(ids)
window.location="/modules/printSelected.xql?ids=" +ids
    /* $.post("/modules/printSelected.xql", {'ids[]': ids
    }).done(function (data) {
        console.log(data);
    });*/
});

/*https://stackoverflow.com/questions/20687884/disable-button-if-all-checkboxes-are-unchecked-and-enable-it-if-at-least-one-is*/
var checkBoxes = $('input.pdf');
checkBoxes.change(function () {
    $('.printgroup').prop('disabled', checkBoxes.filter(':checked').length < 1);
});
checkBoxes.change();