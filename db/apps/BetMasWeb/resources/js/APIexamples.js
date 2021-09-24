
$(document).on('ready', function () {
    
    var url = $('#search');
    var jsonlisturl = $('#jsonlist');
    var baseurl = url.attr('href');
    var jsonlistbaseurl = jsonlisturl.attr('href');
    
    var colselection = '';
    var scriptselection = '';
    var materialselection = '';
    var keywordselection = '';
    var selectors = colselection + scriptselection + materialselection + keywordselection;
    
    $("#collectionjson").on('change', function () {
        var value = $(this).val()
      
     var  newurl = jsonlistbaseurl.replace('works',value)
     
        jsonlisturl.text(newurl)
        getJdata()
    });
   
    $("#query").on('change paste', function () {
        var value = $(this).val()
        var newq = baseurl.replace('Pierre', value)
        console.log(newq)
        url.text(newq + colselection + scriptselection + materialselection + keywordselection)
       
        
        getJdata()
    });
    $("#collection").on('change', function () {
        var value = $(this).val()
        colselection = '&collection=' + value
        url.text( baseurl + colselection + scriptselection + materialselection + keywordselection)
       
        
        getJdata()
    });
    
    $("#script").on('change', function () {
        
        var value = $(this).val()
        scriptselection = '&script=' + value
         url.text( baseurl + colselection + scriptselection + materialselection + keywordselection)
       
        
        getJdata()
    });
    
    $("#material").on('change', function () {
        
        var value = $(this).val()
        materialselection = '&material=' + value
         url.text(baseurl + colselection + scriptselection + materialselection + keywordselection)
       
        
        getJdata()
    });
    
    $("#keyword").on('change', function () {
        
        var value = $(this).val()
        keywordselection = '&keyword=' + value
        url.text(baseurl + colselection + scriptselection + materialselection + keywordselection)
       
        
        getdata()
    });
    
    getJdata()
    getXdata()
})


function getJdata () {
    $('.APIexampleJSON').each(function () {
        var el = this;
        var j = '';
        var urlid = $(this).data('value');
        var apicall = $('#' + urlid).text();
        $.getJSON(apicall, function (data) {
            var str = JSON.stringify(data, undefined, 4);
           
            j += str
           
            
            $(el).html(j);
        });
    })
}
function getXdata () {
    $('.APIexample').each(function () {
        var el = this;
        var urlid = $(this).data('value');
        var apicall = $('#' + urlid).text();
        $.get(apicall, function (data) {
   $(el).append(data)
            
            
        });
    })
}