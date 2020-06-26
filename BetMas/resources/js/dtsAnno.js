function updateindex(indexUrl){   
/*console.log(indexUrl)*/
var api = 'http://localhost:8080/exist/apps/BetMas/' + indexUrl
$.getJSON(api, function (d) {
var nav = '<div class="w3-bar-item w3-grey w3-small" \
><div class="w3-bar"><div class="w3-bar-item w3-tiny indexNavigation" data-nav="'+d.view.first
+'"><i class="fa fa-angle-double-left"></i></div><div class="w3-bar-item w3-tiny indexNavigation" data-nav="'+d.view.previous
+'"><i class="fa fa-angle-left"></i></div><div class="w3-bar-item w3-tiny indexNavigation" data-nav="'+d.view["@id"]
+'"><i class="fa fa-angle-double-down"></i></div><div class="w3-bar-item w3-tiny indexNavigation" data-nav="'+d.view.next
+'"><i class="fa fa-angle-right"></i></div><div class="w3-bar-item w3-tiny indexNavigation" data-nav="'+d.view.last
+'"><i class="fa fa-angle-double-right"></i></div></div></div>'
$('#indexNav').append(nav)
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
   $('#indexNav').append(button)
});
});
};

$('body').on('click', ".DTSannoCollectionLink", function () {
var indexUrl = $(this).data('value') ;
$('#indexNav').empty() ;
/*console.log(indexUrl) ;*/
updateindex(indexUrl) ;
});

$('body').on('click', ".indexNavigation", function () {
var indexUrl = $(this).data('nav')
/*console.log(indexUrl) ;*/
$('#indexNav').empty() ;
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
   <a href=" ' + link + ' " target="_blank" \
   style="word-break:break-all;">' +  ctype + 
   ' '+ ref  + '</a></div>'
   indexItem.after(button)
});
});
});

