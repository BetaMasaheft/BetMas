
$(document).on({
    ajaxStart: function () {
        $("img#loading").show();
    },
    ajaxStop: function () {
        $("img#loading").hide();
         $('#clickandgotoCatalogueID').removeAttr('disabled');
    }
});

$('#loadcatalogues').click(function(){
    $('#loadcatalogues').attr('disabled', 'disabled');
    $('#GoToCatalogue').load('/api/cataloguesZotero')
})
