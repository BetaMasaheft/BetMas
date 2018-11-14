
$(document).on({
    ajaxStart: function () {
        $("img#loading").show();
    },
    ajaxStop: function () {
        $("img#loading").hide();
    }
});

$('#loadcatalogues').click(function(){
    $('#loadcatalogues').attr('disabled', 'disabled');
    $('#GoToCatalogue').load('/api/cataloguesZotero')
    $('#clickandgotoCatalogueID').removeAttr('disabled');
})

$('#loadrepositories').click(function(){
    $('#loadrepositories').attr('disabled', 'disabled');
    $('#GoToRepo').load('/api/listRepositoriesName')
    $('#clickandgotoRepoID').removeAttr('disabled');
})
