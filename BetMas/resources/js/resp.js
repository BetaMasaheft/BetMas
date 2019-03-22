/*

RdgResp --->  title="Reading by {$resp}"
RdgRespMs -->  title="Reading of {@wit} by {$resp}"
CorrResp --> title="Marked as incorrect {if ($resp) then concat('by ', $resp) else ()}"
choiceResp --> title="Corrected {if ($resp) then concat('by ', $resp) else ()} from {$sic}"
OmissionResp --> title="Omission by {$author}"*/

/*thanks to https://stackoverflow.com/questions/287188/how-to-know-when-all-ajax-calls-are-complete where I found out about this event... the elements in which the names are stored, call the api, and it needs to wait for the api call to have finished to find any text in those*/
$(document).ajaxStop(function () {
    
    $("[class$='Resp']").each(function () {
    //takes all the classes ending with Resp, which are entered by divEdition.xsl into the html and contain a data-value with the ids entered in @resp into the TEI files
        var el = this
        var c = $(this).attr('class')
        // on the basis of the actual class name, decide what kind of intervention is to choose an appropriate text to prepose to the names of the authors listed in resp.
        var type = ''
        switch (c) {
            case 'w3-tooltip RdgResp':
            type = "Reading by ";
            break;
            
            case 'w3-tooltip OmissionResp':
            type = "Omitted by ";
            break;
            
            case 'w3-tooltip CorrResp':
            type = "Marked as incorrect by ";
            break;
            
            case 'w3-tooltip choiceResp':
            type = "Corrected by ";
            break;
        }
        
//        gets the number of resps
        var resp = $(this).data('value')
        var all = resp.split(" ")
        var tot = all.length
        var name =[]
        // if they are more then one iterate to check in the correct hidden div
        if (tot > 1) {
            for (var i = 0; i < tot; i++) {
            //resp.xsl called by mss.xsl searches for all @resp values and produces an hidden div containing the id with the class MainTitle, which is used by title.js to call rest.xql and get the correct title for that id.
            // once this element is populated then we take from there the name.
                var n = $('#' + all[i] + 'Name').text()
                // console.log(n)
                name.push(n)
            }
            
            //console.log(name)
        } else {
            var n = $('#' + resp + 'Name').text()
            name.push(n)
          //  console.log(name)
        }
        
        var content = '<span class="w3-text respoptiontooltip">'+ type + name.join(', ') +'</span>'
        $(el).append(content)
    });
    
    $(".RdgRespMs").each(function () {
        var el = this
        var resp = $(this).data('value')
        var all = resp.split(" ")
        var tot = all.length
        var name =[]
        if (tot > 1) {
            for (var i = 0; i < tot; i++) {
                var n = $('#' + all[i] + 'Name').text()
                //console.log(n)
                name.push(n)
            }
            
            //console.log(name)
        } else {
            var n = $('#' + resp + 'Name').text()
            name.push(n)
            //console.log(name)
        }
        
        var authors = name.join(', ')
        var wit = $(this).data('wit')
        var title = 'Reading of ' + wit + ' by ' + authors
        
        $(el).tooltip({
            html: true, title: content
        })
    });
});
