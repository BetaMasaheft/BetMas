function updateindex(indexUrl){   
/*console.log(indexUrl)*/
var api = 'http://localhost:8080/exist/apps/BetMasWeb/' + indexUrl
$.getJSON(api, function (d) {
var last = d.view.last
var ln = last.lastIndexOf('page=')
var totalpages = last.substring(ln+5)
var current = d.view["@id"]
var cn = current.lastIndexOf('page=')
var currentpage = current.substring(cn+5)
var nav = '<div style="padding: 8px 8px;" class="w3-bar-item  indexNavigation" data-nav="'+ d.view.first
+'"><i class="fa fa-angle-double-left"></i></div><div style="padding: 8px 8px;"  class="w3-bar-item indexNavigation" data-nav="'+ d.view.previous
+'"><i class="fa fa-angle-left"></i></div><div style="padding: 8px 8px;"  class="w3-bar-item indexNavigation" data-nav="'+ current
+'">'+currentpage + '/' + totalpages+'</div><div style="padding: 8px 8px;"  class="w3-bar-item  indexNavigation" data-nav="'+ d.view.next
+'"><i class="fa fa-angle-right"></i></div><div style="padding: 8px 8px;"  class="w3-bar-item  indexNavigation" data-nav="'+ last
+'"><i class="fa fa-angle-double-right"></i></div>'
$('#indexnavigation').append(nav)

   var first = d.view.first
   var members = d.member
   $(members).each(function( index ) {
   var i = $(this)
   var id =  i[0]["@id"] 
   var tit = i[0]["shortTitle"]
   var urlnopage =indexUrl.replace(/\?page\=\d+/, '')
/*   console.log(indexUrl)*/
/*   console.log(urlnopage)*/
   var button = 
   '<div class="w3-bar-item w3-red w3-small indexItem" \
    " data-source=" ' +urlnopage  + ' " data-id=" ' +id
    + ' "  target="_blank" style="word-break:break-all;">' + 
   tit + '</div>'
   $('#indexNav').addClass("w3-show");
   $('#indexitems').append(button);
  
});
 var closebutton = 
   '<div class="w3-bar-item w3-gray w3-small CloseIndex">Close</div>'
   $('#indexitems').append(closebutton);
});
};

$('body').on('click', ".DTSannoCollectionLink", function () {
var indexUrl = $(this).data('value') ;
/*console.log(indexUrl) ;*/
$('#indexnavigation').empty() ;
$('#indexitems').empty() ;
updateindex(indexUrl) ;
});


$('body').on('click', ".CloseIndex", function () {
$('#indexnavigation').empty() ;
$('#indexitems').empty() ;
});

$('body').on('click', ".indexNavigation", function () {
var indexUrl = $(this).data('nav')
/*console.log(indexUrl) ;*/
$('#indexnavigation').empty() ;
$('#indexitems').empty() ;
updateindex(indexUrl) ;
});

$('body').on('click', '.indexItem', function () {
var indexItem = $(this)
var indexUrl = indexItem.data('source')
var dtsanno = indexItem.data('id')
var api = 'http://localhost:8080/exist/apps/BetMas'+$.trim(indexUrl)+'?id='+$.trim(dtsanno)
/*console.log(api)*/
$.getJSON(api, function (d) {
   var members = d.member
   $(members).each(function( index ) {
   var i = $(this)
   var link =  i[0].target.source.link
   var ctype = i[0].target.source["dts:citeType"]
   var ref = i[0].target.source["dts:ref"]
   var button = 
   '<div class="w3-bar-item w3-black w3-small indexItem"> \
   <a class="page-scroll" href="#' + ref + '"\
   style="word-break:break-word;">' +  ctype + 
   ' '+ ref  + '<a href=" ' + link + ' " target="_blank" class="w3-right" \
   >↗</a></div>'
   indexItem.after(button)
});
});
});

