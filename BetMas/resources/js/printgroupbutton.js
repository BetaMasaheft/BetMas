$(document).on('ready', function(){
    
    $('#optionsList').append('<button class="w3-button w3-gray printgroup">PDF</button>')
    var checkBoxes = $('input.pdf');
checkBoxes.change();

var url = window.location.pathname
if(url.includes('works/list')){
$('#optionsList').append('<button class="w3-button w3-gray  mapgroup">Manuscripts Map</button>')
    var checkBoxes = $('input.mapSelected');
checkBoxes.change();    
}
else {
$('#optionsList').append('<button class="w3-button w3-gray  comparegroup">Compare</button>')
    var checkBoxes = $('input.compareSelected');
checkBoxes.change();
}
});

$("#select_all_print").change(function (){
    $('input.pdf').prop('checked', $(this).is(':checked'))
});

$("#select_all_compare").change(function (){
    $('input.compareSelected').prop('checked', $(this).is(':checked'))
});

$("#select_all_map").change(function (){
    $('input.mapSelected').prop('checked', $(this).is(':checked'))
});

