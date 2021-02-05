
$('#SType').change(function() {
var fields = document.getElementById('fields')
var xpath = document.getElementById('xpath')
var list = document.getElementById('lists')
var sparql = document.getElementById('sparqls')
 if($(this).val() === 'fields'){fields.className += " w3-show"} else {fields.className =  fields.className.replace(" w3-show", "")}
  if($(this).val() === 'sparql'){sparql.className += " w3-show"} else {sparql.className =  sparql.className.replace(" w3-show", "")}
  if($(this).val() === 'xpath'){xpath.className += " w3-show"} else {xpath.className =  xpath.className.replace(" w3-show", "")}
  if($(this).val() === 'lists'){list.className += " w3-show"} else {list.className =  list.className.replace(" w3-show", "")}
});

/*remove or disable text box for sparql and xpath not to confuse usage.*/