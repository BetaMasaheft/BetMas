$('td[class$="percentfirstquarter"]').each(function() {
   var id = $(this).attr('class').replace('percentfirstquarter','')
   var counts = $('td[class="'+id+'firstquarter"]:contains("x")').length
    var total   = parseInt($('td[class="'+id+'totalMss"]').text())
    var percent = (counts / total) * 100
   $(this).text(percent + '%')
   });
   
   $('td[class$="percentsecondquarter"]').each(function() {
   var id = $(this).attr('class').replace('percentsecondquarter','')
    var counts = $('td[class="'+id+'secondquarter"]:contains("x")').length
   var total   = parseInt($('td[class="'+id+'totalMss"]').text())
   var percent = (counts / total) * 100
  $(this).text(percent + '%')
   });
   
   $('td[class$="percentthirdquarter"]').each(function() {
   var id = $(this).attr('class').replace('percentthirdquarter','')
   var counts = $('td[class="'+id+'thirdquarter"]:contains("x")').length
   var total   = parseInt($('td[class="'+id+'totalMss"]').text())
  var percent = (counts / total) * 100
  $(this).text(percent + '%')
   });
   
   $('td[class$="percentfourthquarter"]').each(function() {
   var id = $(this).attr('class').replace('percentfourthquarter','')
   var counts = $('td[class="'+id+'fourthquarter"]:contains("x")').length
    var total   = parseInt($('td[class="'+id+'totalMss"]').text())
   var percent = (counts / total) * 100
  $(this).text(percent + '%')
   });