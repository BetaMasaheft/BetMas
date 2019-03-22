
$(document).on('ready', function () {

$(".searchthis").on('click', function () {
// clicking on one title copies it to a text input (so it can be modified)
var title = $(this).data('value')
var tit = $('p[data-value="'+title+'"]').text()
var TITL = title.toString()
var TITLE = TITL.indexOf('TITLE')
var id = TITL.substr(0,TITLE)
$("input#"+id).val(tit)
var querystring =  $("input#"+id).val()
console.log(querystring)
var searchurl = 'https://db.bradypus.net/api/paths/works/?verb=search&type=fast&string=' + encodeURIComponent(querystring)
console.log(searchurl)
  $.getJSON(searchurl, function (data) {
    var res = data.records
    var resl = res.length

    console.log(res)
    var options = ""
           $(res).each(function(i){
             var item = this
             var cmcl = item.cmcl
             var title = item.title
             var desc = item.problems
             var cpg = item.cpg
             var cant = item.cant
             var cavt = item.cavt
             var bho = item.bho
             var bhl = item.bhl
             var bhg = item.bhg
                var option = '<form action="/edit/clavisUpdate.xql"  method="post"><h4>'+ title + '</h4><div class="w3-container"><div><input hidden="hidden" name="id" value="'+id+'"/><label>CMCL</label><input class="w3-input w3-border" name="cmcl" value="'+ cmcl +'"/></div><div><label>CAVT</label><input class="w3-input w3-border" name="cavt" value="'+ cavt +'"/></div><div><label>CANT</label><input class="w3-input w3-border" name="cant" value="'+ cant +'"/></div><div><label>BHG</label><input class="w3-input w3-border" name="bhg" value="'+ bhg +'"/></div><div><label>BHL</label><input class="w3-input w3-border" name="bhl" value="'+ bhl +'"/></div><div><label>BHO</label><input class="w3-input w3-border" name="bho" value="'+ bho +'"/></div><div><label>CPG</label><input class="w3-input w3-border" name="cpg" value="'+ cpg +'"/><div><div><p>'+ desc + '</p></div><button type="submit" class="w3-button w3-red">Add to '+id+'</button></form>'
                 options+= option

             });

  $("input#"+id).next('div').html(options)
      });
});
});

$("input.querystring").on('change', function () {
var querystring =  $(this).val()
var ID = $(this).attr( "id" )
console.log(querystring)
console.log(ID)
var searchurl = 'https://db.bradypus.net/api/paths/works/?verb=search&type=fast&string=' + encodeURIComponent(querystring)
console.log(searchurl)
  $.getJSON(searchurl, function (data) {
    var res = data.records
    var resl = res.length
    console.log(res)
    var options = ""
    $(res).each(function(i){
      var item = this
      var cmcl = item.cmcl
      var title = item.title
      var desc = item.problems
      var cpg = item.cpg
      var cant = item.cant
      var cavt = item.cavt
      var bho = item.bho
      var bhl = item.bhl
      var bhg = item.bhg
         var option = '<form action="/edit/clavisUpdate.xql"  method="post"><h4>'+ title + '</h4><div class="w3-container"><input hidden="hidden" name="id" value="'+ID+'"/><div><label>CMCL</label><input class="w3-input w3-border" name="cmcl" value="'+ cmcl +'"/></div><div><label>CAVT</label><input class="w3-input w3-border" name="cavt" value="'+ cavt +'"/></div><div><label>CANT</label><input class="w3-input w3-border" name="cant" value="'+ cant +'"/></div><div><label>BHG</label><input class="w3-input w3-border" name="bhg" value="'+ bhg +'"/></div><div><label>BHL</label><input class="w3-input w3-border" name="bhl" value="'+ bhl +'"/></div><div><label>BHO</label><input class="w3-input w3-border" name="bho" value="'+ bho +'"/></div><div><label>CPG</label><input class="w3-input w3-border" name="cpg" value="'+ cpg +'"/><div><div><p>problems</p><small>'+ desc + '</small></div><button type="submit" class="w3-button w3-red">Add to '+ID+'</button></form>'
          options+= option

      });

  $("input#"+ID).next('div').html(options)

});
});



