
$('#suffix').on('change paste keyup', function () {
    
    var empty = false;
    $('#suffix').each(function () {
        if ($(this).val() == '') {
            empty = true;
        }
    });
    
    if (empty) {
        $('#confirmcreatenew').attr('disabled', 'disabled');
        // updated according to http://stackoverflow.com/questions/7637790/how-to-remove-disabled-attribute-with-jquery-ie
    } else {
        $('#confirmcreatenew').removeAttr('disabled');
        // updated according to http://stackoverflow.com/questions/7637790/how-to-remove-disabled-attribute-with-jquery-ie
    }
});

$('#group').change( function () {
    if ($('#group').is(":checked")) {
        $('#male').attr('disabled', 'disabled');
        $('#female').attr('disabled', 'disabled');
    } else {
        $('#male').removeAttr('disabled');
        $('#female').removeAttr('disabled');}
    });