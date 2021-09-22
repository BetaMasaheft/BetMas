$("input[name='query']").on('change paste keyup',function () {
var inputtext = $(this).val()
    if (inputtext.length > 15) {
        $("input[name='homophones']").removeAttr('checked')
        $("input[name='homophones']").text('homophones substitutions are limited to query of up to 15 characters')
    } else {$("input[name='homophones']").prop('checked', true)}
});