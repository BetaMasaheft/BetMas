
$("span[id$='relations']").on('click', function () {
    var el = this;
     var popText = $(this).prev().text()
/*    check if there is already a popover*/
    if ($(this).children('div').hasClass('popuptext')) {
       //console.log('there is already a popoup here, load it');
      var popupID = $(this).children('div').attr('id')
      //console.log(popupID)
      //console.log(popText)
        popup(popupID)
    } else {
/*    there is no popover, lets make one*/
        var id = this.id;
/*get the item id from the complex id (legacy...)*/
var trimmedID = id.substring((id.indexOf('Ent') + 3), id.indexOf('relations'));

/*        make the query to the api */
        var callsparql = '/api/SPARQL/relations/' + trimmedID
/*        disable the button*/
        $(el).attr("disabled", "disabled");
        $.getJSON(callsparql, function (data) {
            //console.log(data)
/*            if there are no contents, data.info will be there, then destroy the temporary popover and make one saying so.*/
            if (data.info) {
                $(el).append('<div id="' + trimmedID + 'relations-content" class="popuptext w3-hide w3-tiny w3-padding" style="width: 260px;background-color: black;\
                color: white;text-align: center;border-radius: 6px;padding: 8px 0;position: absolute;left: 100%;top: 100%;margin-left: -130px;z-index: 999;overflow-y:auto">'
                +data.info+'</div>')
            } else {
            
/*            if there are results,  destroy the temporary popover and make one with the contents.*/
                $(el).removeAttr("disabled");
                var content = $('<div id="' + trimmedID + 'relations-content" class="popuptext w3-hide w3-tiny w3-padding" style="width: 260px;background-color: black;\
                color: white;text-align: center;border-radius: 6px;padding: 8px 0;position: absolute;left: 100%;top: 100%;margin-left: -130px;z-index: 999;overflow-y:auto">\
                Search '+popText+' :<br/>\
            <a href="/newSearch.html?query='+popText+'" target="_blank">in Beta maṣāḥǝft</a><br/>\
            <a href="/morpho?query='+popText+'" target="_blank">in the Gǝʿǝz Morphological Parser</a><br/>\
            <a href="/morpho/corpus?query='+popText+'&type=string" target="_blank">in the TraCES annotations</a><br/>\
            <a href="/Dillmann?mode=fuzzy&q='+popText+'" target="_blank">in the Online Lexicon</a><br/>\
                <ul xmlns="http://www.w3.org/1999/xhtml" class="nodot"><head xmlns="http://www.w3.org/1999/xhtml" >This record, with ID: ' + trimmedID + ' is linked to </head></div>');
                var length = data.length
                
                $(data).each(function(i){
                    $(content).append('<li><a target="_blank" href="' + this.id + '">' + this.title + '</a> by ' + this.relation + '</li>')
                })
                 
                $(el).append(content)
            }
        });
        /*    tecnique copied from https://www.raymondcamden.com/2015/04/03/strategies-for-dealing-with-multiple-ajax-calls/*/
    }
});

$("a[id^='date']").each(function () {
    var id = this.id;
    var trimmedID = id.substring((id.indexOf('date') + 4), id.indexOf('calendar'));
    var el = this;
    var content = $('#dateInfo' + trimmedID);
    
    $(el).append(content)
});