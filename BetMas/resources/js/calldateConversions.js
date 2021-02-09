$(document).ready(function() {

  $('time').each(function() {

    $(this).attr('data-tooltip', convertDate(
      $(this).attr('data-calendar'),
      $(this).attr('data-year'),
      $(this).attr('data-month'),
      $(this).attr('data-day'),
      $(this).attr('data-era')
    ));

    $(this).addClass('has-tooltip-arrow');

  });

});