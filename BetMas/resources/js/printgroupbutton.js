$(document).on('ready', function(){
    
    $('#optionsList').append('<button class="btn btn-success printgroup">Print PDF with all selected items</button>')
    var checkBoxes = $('input.pdf');
checkBoxes.change();

$('#optionsList').append('<button class="btn btn-primary comparegroup">Compare selected items</button>')
    var checkBoxes = $('input.compareSelected');
checkBoxes.change();

});

$("#select_all_print").change(function (){
    $('input.pdf').prop('checked', $(this).is(':checked'))
});

$("#select_all_compare").change(function (){
    $('input.compareSelected').prop('checked', $(this).is(':checked'))
});

