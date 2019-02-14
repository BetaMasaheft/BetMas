$("#menu-toggleside").click(function (e) {
    e.preventDefault();
    $("#wrapperone").toggleClass("toggledone");
});

$(function () {
    
    $('.list-group-item').on('click', function () {
        $('.glyphicon', this).toggleClass('glyphicon-chevron-right').toggleClass('glyphicon-chevron-down');
    });
});
$(document).ready(function () {
    $('[data-toggle="popover"]').popover();
    $('[data-toggle="tooltip"]').tooltip();
    
});

/*https://stackoverflow.com/questions/33092386/how-to-determine-if-a-bootstrap-collapse-is-opening-or-closing*/
$("#NavByIds").on('show.bs.collapse', function() {
    $(".allMainRel").hide()    
});

$('#NavByIds').on('hidden.bs.collapse', function () {
   $(".allMainRel").show()
});

/*$('.accordion-group .collapse').collapse('show');*/

$("#tooglecodicologicalInformation").click(function () {
    $('[id^="codicologicalInformation"]').toggle("slow");
});

$("#toggleHands").click(function () {
    $('.fa-hand-o-left').toggle("slow");
    $('span.pelagios').toggle("slow");
});

$("#toogletextualcontents").click(function () {
    $('[id^="textualcontents"]').toggle("slow");
});

$("#toogleimages").click(function () {
    $('.miradorBOX').toggle("slow");
});


$("#NavByIds").is(':visible') 