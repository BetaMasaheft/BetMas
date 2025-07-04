 var monitor = setInterval(function(){
                    var elem = document.activeElement;
                    if(elem && elem.id == 'unlocked-video'){
                    document.getElementById('vidimg').style.display='none';
                    clearInterval(monitor);
                    }
                    }, 300);