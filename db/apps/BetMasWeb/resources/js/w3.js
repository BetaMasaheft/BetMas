function w3_open() {
  document.getElementById("main").style.marginLeft = "20%";
  document.getElementById("sidebar").style.width = "20%";
  document.getElementById("sidebar").style.display = "block";
}

function w3_close() {
  document.getElementById("main").style.marginLeft = "0%";
  document.getElementById("sidebar").style.display = "none";
}

function w3_openItemSB() {
  document.getElementById("main").style.marginLeft = "10%";
  document.getElementById("sidebar").style.width = "10%";
  document.getElementById("sidebar").style.display = "block";
}

function w3_closeItemSB() {
  document.getElementById("main").style.marginLeft = "0%";
  document.getElementById("sidebar").style.display = "none";
}

// used to open tabs in different languages
function openIntro(introLang) {
  var i;
  var x = document.getElementsByClassName("introText");
  for (i = 0; i < x.length; i++) {
    x[i].style.display = "none"; 
  }
  document.getElementById(introLang).style.display = "block"; 
}

// used to open tabs in different languages
function openSummary(type) {
  var i;
  var x = document.getElementsByClassName("summaryText");
  for (i = 0; i < x.length; i++) {
    x[i].style.display = "none"; 
  }
  document.getElementById(type).style.display = "block"; 
}

function showRes(type) {
  var i;
  var x = document.getElementsByClassName("queryresults");
  for (i = 0; i < x.length; i++) {
    x[i].style.display = "none"; 
  }
  document.getElementById(type).style.display = "block"; 
}

// Used to toggle the menu on small screens when clicking on the menu button
function myFunction() {
  var x = document.getElementById("navDemo");
  if (x.className.indexOf("w3-show") == -1) {
    x.className += " w3-show";
  } else { 
    x.className = x.className.replace(" w3-show", "");
  }
}

//accordion opener

function openAccordion(id) {
  var x = document.getElementById(id);
  if (x.className.indexOf("w3-show") == -1) {
    x.className += " w3-show";
  } else { 
    x.className = x.className.replace(" w3-show", "");
  }
}

$(document).ready(function () {
    $('.openInDialog').click(function () {
    var dial = $('<div class="w3-container w3-padding w3-margin"/>')
    var content = $('<div class="w3-container w3-padding"/>')
    var head = $(this).clone().appendTo(dial)
    var list = $(this).next()
    list.clone().appendTo(content);
    content.appendTo(dial)
    $('#main').append(dial)
        dial.dialog({
        dialogClass: "w3-container w3-white w3-border ",
            width: 600,
            modal: true,
            click: function() {
        $( this ).dialog( "close" );
      }
        });
    });
});

$(function() {
    $('a.page-scroll').bind('click', function(event) {
        var $anchor = $(this);
        $('html, body').stop().animate({
            scrollTop: $($anchor.attr('href')).offset().top
        }, 1500, 'easeInOutExpo');
        event.preventDefault();
    });
});

$('#perpagechange').on('change', function(){
console.log('sending new request!')
var value = $(this).val()
    var url = new URL(window.location.href);
url.searchParams.set('per-page',value);
window.location.href = url.href;
});

function popup(id) {
  var x = document.getElementById(id);
  if (x.className.indexOf("w3-show") == -1) {
    x.className += " w3-show";
  } else { 
    x.className = x.className.replace(" w3-show", "");
  }
}

$("a[id^=toggle]").click(function(){
  $(this).find('.showHideText').text(($(this).find('.showHideText').text() == 'Hide' ? 'Show' : 'Hide'));
});

$("#toggleHands").click(function () {
    $('.fa-hand-o-left').toggle("slow");
    $('.glyphicon-hand-left').toggle("slow");
    $('.fa-calendar-plus-o').toggle("slow");
    $('span.pelagios').toggle("slow");
});

$("#togglecodicologicalInformation").click(function () {
    $('[id^="codicologicalInformation"]').toggle("slow");
});

$("#toggletextualcontents").click(function () {
    $('[id^="textualcontents"]').toggle("slow");
});

$("#toggleSeeAlso").click(function () {
    $('[id^="seeAlsoForm"]').toggle("slow");
   var x = document.getElementById('MainData'); 
    x.classList.toggle("w3-container");
     x.classList.toggle("w3-twothird");
});

$("#toogleTextBibl").click(function () {
    $('[id^="bibliographyText"]').toggle("slow");
   var x = document.getElementById('dtstext'); 
    x.classList.toggle("w3-container");
     x.classList.toggle("w3-twothird");
});

$("#toogleNavIndex").click(function () {
/*console.log('toggled index')*/
    $("#refslist").toggle("slow");
});

$('.slider').css('width','100%');

$('time').each(function() {
console.log( $(this).attr('data-calendar'))
var date = convertDate(
      $(this).attr('data-calendar'),
      $(this).attr('data-year'),
      $(this).attr('data-month'),
      $(this).attr('data-day'),
      $(this).attr('data-era')
    )
    $(this).append('<span class="w3-red"> = '+date+' </span>');


  });
  
  
  // Automatically patch <a> elements with data-viewerurl to set their href at page load
document.addEventListener("DOMContentLoaded", function() {
  document.querySelectorAll('a[data-viewerurl]').forEach(function(a) {
    a.setAttribute('href', a.getAttribute('data-viewerurl'));
    a.setAttribute('target', '_blank'); // optional: opens viewer in new tab
  });
});
