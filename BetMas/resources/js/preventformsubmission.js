$('input').on('change paste keyup', function () {
    var VAL = this.value
    //console.log(VAL)
    var regex = new RegExp("[\']")
    if (regex.test(VAL)) {
        //console.log('error!')
        alert("You have used a reserved character, please avoid '.")
        $(this).parent().addClass('has-error')
        $('#submit-data').attr('disabled', 'disabled')
        $('button[@type="submit"]').attr('disabled', 'disabled')
    } else {
        $(this).parent().removeClass('has-error')
        $('#submit-data').removeAttr('disabled')
        $('button[@type="submit"]').removeAttr('disabled')
    }
});