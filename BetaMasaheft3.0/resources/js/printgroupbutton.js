$(document).on('ready', function(){
    
    $('.col-md-12 > .pagination').append('<li><button class="btn btn-default printgroup">Print PDF with all selected items</button></li>')
    var checkBoxes = $('input.pdf');
checkBoxes.change();
});

