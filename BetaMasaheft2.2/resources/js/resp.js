/*

RdgResp --->  title="Reading by {$resp}"
RdgRespMs -->  title="Reading of {@wit} by {$resp}"
CorrResp --> title="Marked as incorrect {if ($resp) then concat('by ', $resp) else ()}"
choiceResp --> title="Corrected {if ($resp) then concat('by ', $resp) else ()} from {$sic}"
OmissionResp --> title="Omission by {$author}"*/


 $(".OmissionResp").each(function() {
        var el = this
           var resp = $(this).data('value')
           var name =  $('#' + resp + 'Name')
  
   $(el).tooltip({html : true, title: name})
});
       
  $(".ChoiceResp").each(function() {
        var el = this
           var resp = $(this).data('value')
           var name =  $('#' + resp + 'Name')
  
   $(el).tooltip({html : true, title: name})
});    

$(".CorrResp").each(function() {
        var el = this
           var resp = $(this).data('value')
           var name =  $('#' + resp + 'Name')
  
   $(el).popover({html : true, content: name
                            , title: 'Marked as incorrect by'})
});

$(".RdgResp").each(function() {
        var el = this
           var resp = $(this).data('value')
           var name =  $('#' + resp + 'Name')
  
   $(el).tooltip({html : true, title: name})
});

$(".RdgRespMs").each(function() {
        var el = this
           var resp = $(this).data('resp')
           var wit = $(this).data('wit')
           var name =  $('#' + resp + 'Name')
           var title = 'Reading of ' + wit + ' by ' 
  
   $(el).popover({html : true, content: name
                            , title: title})
});




