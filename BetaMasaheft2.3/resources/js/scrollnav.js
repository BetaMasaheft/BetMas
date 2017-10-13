//jQuery for page scrolling feature - requires jQuery Easing plugin
//https://stackoverflow.com/questions/23227093/how-to-set-up-a-link-to-later-on-a-page-but-aligning-the-target-with-the-botto
$(function() {
    $('a.page-scroll').bind('click', function(event) {
        var $anchor = $(this);
        $('html, body').stop().animate({
            scrollTop: $($anchor.attr('href')).offset().top
        }, 1500, 'easeInOutExpo');
        event.preventDefault();
    });
});