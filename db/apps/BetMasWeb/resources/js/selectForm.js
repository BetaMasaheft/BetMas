
$('#SType').change(function () {
    var fields = document.getElementById('fields')
    var xpath = document.getElementById('xpath')
    var list = document.getElementById('lists')
    var sparql = document.getElementById('sparqls')
    var otherclavis = document.getElementById('otherclavis')
    if ($(this).val() === 'fields') {
        fields.className += " w3-show"
    } else {
        fields.className = fields.className.replace(" w3-show", "")
    }
    if ($(this).val() === 'sparql') {
        sparql.className += " w3-show"
        document.getElement('input[@name="query"]').replace('<textarea \
                                         class="w3-input w3-border" id="sparql" \
                                         name="query" style="height:200px" \
                                         placeholder="Please enter a valid SPARQL query.">\
                                        </textarea>')
                /*<input xmlns="" name="query" type="search" class="w3-input  w3-border diacritics ui-keyboard-input ui-widget-content ui-corner-all" placeholder="type here the text you want to search" value="" aria-haspopup="true" role="textbox">     */                   
    } else {
        sparql.className = sparql.className.replace(" w3-show", "")
    }
    if ($(this).val() === 'xpath') {
        xpath.className += " w3-show";
    } else {
        xpath.className = xpath.className.replace(" w3-show", "")
    }
    if ($(this).val() === 'otherclavis') {
        otherclavis.className += " w3-show"
    } else {
        otherclavis.className = otherclavis.className.replace(" w3-show", "")
    }
});

$("#showfilters").one("click", function () {
/*$("#filters").className += " w3-show"*/
    callformpart('filters.html', 'advanced');
});

$("#showfilters").click(function () {
    $('.filter').toggle("slow");
});

$("#showfields").click(function () {
console.log('fields')
var fields = document.getElementById('fields')
    fields.className += " w3-show"
});


function callformpart(file, id) {
    
    // check first that the element is not there already
    var myElem = document.getElementById(id);
    // if it is not there, load it
    if (myElem === null) {
        $.ajax(file, {
            success: function (data) {
            //console.log(data)
                $("#filters").append(data);
            }
        });
    }
    // else it has already been loaded, therefore simply show it.
    var jid = '#' + id
    $(jid).toggle();
};

/*remove or disable text box for sparql and xpath not to confuse usage.*/