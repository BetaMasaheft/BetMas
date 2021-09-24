
function makeSPARQLQuery(endpointUrl, sparqlQuery, doneCallback) {
    var settings = {
        headers: {
            Accept: 'application/sparql-results+json'
        },
        data: {
            query: sparqlQuery
        }
    };
    return $.ajax(endpointUrl, settings).then(doneCallback);
}

$(document).on('ready', function () {
    var Europeana = $("#EuropeanaMatches")
    $(Europeana).children('div').each(function () {
        var iconID = $(this).data('value')
        var iconclass = $(this)
        var iconclassNumber = iconID.replace('ic:', '')
        /*var query = 'http://sparql.europeana.eu/?default-graph-uri=http%3A%2F%2Fdata.europeana.eu%2F&query=SELECT+%3FProvidedCHO%0D%0AWHERE+%7B%0D%0A++%3FProxy+%3Fproperty+%3Chttp%3A%2F%2Ficonclass.org%2F'+iconclassNumber+'%3E+%3B%0D%0A+++++++++ore%3AproxyIn+%3FAggregation+.+%0D%0A++%3FAggregation+edm%3AaggregatedCHO+%3FProvidedCHO%0D%0A%7D&format=application%2Fsparql-results%2Bjson&timeout=0&debug=on'*/
        /*$.getJSON(query,function(data) {
        
        //console.log(data)
        var bds = data.results.bindings
        var matches = bindgins.length
        if(matches >= 1) {
        $(iconclass).append('<h3>'+matches+' items related to <a href="http://www.iconclass.org/'+iconclassNumber+'">Iconclass '+iconclassNumber+'</a> from <a href="http://sparql.europeana.eu/" target="_blank">Europeana SPARQL</a></h3>')
        
        $(bds).each(function(linkshere){
        var relatedItem = '<div class="w3-container"><p class="w3-large"><a href="'+this.ProvidedCHO.value+'">' + linkshere + '</a> </p></div>'
        $(iconclass).append(relatedItem)
        });}
        });*/
        
        
        
        var endpointUrl = 'https://query.wikidata.org/sparql'
        
        var sparqlQuery = "SELECT ?item ?commonsCat ?itemLabel \n" +
        "WHERE \n" +
        "{\n" +
        "  ?item wdt:P1256 '" + iconclassNumber + "';\n" +
        "        wdt:P373 ?commonsCat .\n" +
        "  SERVICE wikibase:label { bd:serviceParam wikibase:language \"[AUTO_LANGUAGE],en\". }\n" +
        "}";
        
        makeSPARQLQuery(endpointUrl, sparqlQuery, function (data) {
            console.log(data);
            var bds = data.results.bindings
            $(bds).each(function (linkshere) {
                var relatedItem = '<li>Link to Wikidata entity <a href="' + this.item.value + '">' + this.itemLabel.value + '</a></li>'
                var cc = this.commonsCat
                $(cc).each(function (){
                $("#EuropeanaMatches").children('div').children('ul').append('<li>Wikimedia Commons Category <a href="https://commons.wikimedia.org/wiki/Category:'+this.value+'">'
                +this.value+'</a></li>'
               )});
                $("#EuropeanaMatches").children('div').children('ul').append(relatedItem)
            });
        });
    });
});