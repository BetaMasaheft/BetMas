 $("td[id^='bm']").each(function() {
           var apiurl = "https://api.zotero.org/groups/358366/items?&tag=" ;
           var style = "&format=bib&style=hiob-ludolf-centre-for-ethiopian-studies" ;
        var id = this.id;
   var el = this
     var call = apiurl + id + style
   $(el).load(call);
});


 $("div[id^='bm']").each(function() {
           var apiurl = "https://api.zotero.org/groups/358366/items?&tag=" ;
           var style = "&format=bib&style=hiob-ludolf-centre-for-ethiopian-studies" ;
        var id = this.id;
   var el = this
     var call = apiurl + id + style
   $(el).load(call);
});