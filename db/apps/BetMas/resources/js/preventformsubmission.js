$('input').on('change paste keyup', function () {
    var VAL = this.value
    //console.log(VAL)
    var regex = new RegExp("[\']")
    if (regex.test(VAL)) {
        //console.log('error!')
        alert("You have used a reserved character, please avoid '.")
        $(this).parent().addClass('has-error')
        $('#submit-data').attr('disabled', 'disabled')
        $('#f-btn-search').attr('disabled', 'disabled')
    } else {
        $(this).parent().removeClass('has-error')
        $('#submit-data').removeAttr('disabled')
        $('#f-btn-search').removeAttr('disabled')
    }
});