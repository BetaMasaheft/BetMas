 $('.explain').on('mouseover mouseout',function () {
        var id = $(this).data('value') 
        // console.log(id)
        explainer(id)
        })
        
        function explainer(id) {
        var explanationtext = document.getElementById(id);
          //   console.log(explanationtext)
        if (explanationtext.className.indexOf("w3-show") == -1) {
         // console.log(explanationtext.className  + ' add SHOW ');
        explanationtext.className += " w3-show";  
        //console.log(explanationtext.className  + ' added SHOW ');
        } else { 
    //console.log(explanationtext.className + ' remove SHOW ');
        explanationtext.className = explanationtext.className.replace(" w3-show", "");
   // console.log(explanationtext.className  + ' removed SHOW ');
        }
        }