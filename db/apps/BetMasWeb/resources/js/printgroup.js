

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
//console.log(ids)
window.location="/compareSelected?mss=" +ids
});

//titles

$(document).on('click', '.titlesgroup', function(){
    var ids = []
    
    $('input.compareSelected').each(function() {
    if($(this).is(':checked')){ids.push($(this).data('value'))} 
    });
     $('input.mapSelected').each(function() {
    if($(this).is(':checked')){ids.push($(this).data('value'))} 
    });
console.log(ids)
var url = window.location.pathname
if(url.includes('works/list')){window.location="/titles?limit-work=" +ids}
else {window.location="/titles?limit-mss=" +ids}

});



/*https://stackoverflow.com/questions/20687884/disable-button-if-all-checkboxes-are-unchecked-and-enable-it-if-at-least-one-is*/
var checkBoxesComp = $('input.compareSelected');
checkBoxesComp.change(function () {
    $('.comparegroup').prop('disabled', checkBoxesComp.filter(':checked').length < 1);
    $('.titlesgroup').prop('disabled', checkBoxesComp.filter(':checked').length < 1);
});
checkBoxesComp.change();



/* works map */

$(document).on('click', '.mapgroup', function(){
    var ids = []
    
    $('input.mapSelected').each(function() {
    if($(this).is(':checked')){ids.push($(this).data('value'))} 
    });
console.log(ids)
window.location="/workmap?worksid=" +ids
});

var checkBoxesMap = $('input.mapSelected');
checkBoxesMap.change(function () {
    $('.mapgroup').prop('disabled', checkBoxesMap.filter(':checked').length < 1);
});
checkBoxesMap.change();
