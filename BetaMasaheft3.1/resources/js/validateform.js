$('#createnew').submit(function () {
    var wikidata = $('#Wdata').val()
    if (wikidata){ 
    var wd = /^Q\d+$/g.test(wikidata)
    if (wd === false) {
        alert("wikidata item id must match Q and a series of numbers ");
        return false;
        }
        }
});
