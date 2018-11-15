

/*print*/

$(document).on('click', '.printgroup', function(){
    var ids = []
    
    $('input.pdf').each(function() {
    if($(this).is(':checked')){ids.push($(this).data('value'))} 
    });
console.log(ids)
window.location="/modules/printSelected.xql?ids=" +ids
});

/*https://stackoverflow.com/questions/20687884/disable-button-if-all-checkboxes-are-unchecked-and-enable-it-if-at-least-one-is*/
var checkBoxes = $('input.pdf');
checkBoxes.change(function () {
    $('.printgroup').prop('disabled', checkBoxes.filter(':checked').length < 1);
});
checkBoxes.change();



/*compare*/



$(document).on('click', '.comparegroup', function(){
    var ids = []
    
    $('input.compareSelected').each(function() {
    if($(this).is(':checked')){ids.push($(this).data('value'))} 
    });
console.log(ids)
window.location="/compareSelected?mss=" +ids
});

/*https://stackoverflow.com/questions/20687884/disable-button-if-all-checkboxes-are-unchecked-and-enable-it-if-at-least-one-is*/
var checkBoxesComp = $('input.compareSelected');
checkBoxesComp.change(function () {
    $('.comparegroup').prop('disabled', checkBoxesComp.filter(':checked').length < 1);
});
checkBoxesComp.change();