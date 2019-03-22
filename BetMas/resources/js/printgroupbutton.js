$(document).on('ready', function(){
    
    $('#optionsList').append('<button class="w3-button w3-gray printgroup">PDF</button>')
    var checkBoxes = $('input.pdf');
checkBoxes.change();

$('#optionsList').append('<button class="w3-button w3-gray  comparegroup">Compare</button>')
    var checkBoxes = $('input.compareSelected');
checkBoxes.change();

});

$("#select_all_print").change(function (){
    $('input.pdf').prop('checked', $(this).is(':checked'))
});

$("#select_all_compare").change(function (){
    $('input.compareSelected').prop('checked', $(this).is(':checked'))
});

