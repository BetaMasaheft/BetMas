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
});
$(document).ready(function () {
    $('[data-toggle="tooltip"]').tooltip();
});

$('.accordion-group .collapse').collapse('show');

$("#tooglecodicologicalInformation").click(function () {
    $('[id^="codicologicalInformation"]').toggle("slow");
});

$("#toogletextualcontents").click(function () {
    $('[id^="textualcontents"]').toggle("slow");
});

$("#toogleimages").click(function () {
    $('.miradorBOX').toggle("slow");
});
