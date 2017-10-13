  var slider = document.getElementById('slider');
                            
                            noUiSlider.create(slider, {
                            start: [1300, 1700],
                            step: 50, //step of 50 years?
                            connect: true,
                            behaviour: 'tap-drag',
                            range: {
                            'min': 1000,
                            'max': 1900
                            },
                            pips: { // Show a scale with the slider
                            mode: 'steps',
                            density: 2
                            }
                            
                            });
 
  var dateValues = [
                            document.getElementById('event-start'),
                            document.getElementById('event-end')
                            ];
                            
                            slider.noUiSlider.on('update', function( values, handle ) {
                            dateValues[handle].innerHTML = values[handle];
                            });
                            
                            
var valueInput = document.getElementById('value-input');
                            
                            // When the slider value changes, update the input and span
                            slider.noUiSlider.on('update', function( values, handle ) {
                            if ( handle ) {
                            valueInput.value = values[handle];
                            } else {
                            valueInput.innerHTML = values[handle];
                            }
                            });
                            
                            // When the input changes, set the slider value
                            valueInput.addEventListener('change', function(){
                            slider.noUiSlider.set([null, this.value]);
                            });
 
 var slider = document.getElementById('LifeSlider');
                            
                            noUiSlider.create(slider, {
                            start: [1459, 1512],
                            step: 2, //step of 50 years?
                            connect: true,
                            behaviour: 'tap-drag',
                            range: {
                            'min': 1000,
                            'max': 1900
                            }
                            
                            });

var dateValues = [
                            document.getElementById('birth'),
                            document.getElementById('death')
                            ];
                            
                            LifeSlider.noUiSlider.on('update', function( values, handle ) {
                            dateValues[handle].innerHTML = values[handle];
                            });
 
 
 var valueInput = document.getElementById('dates-input');
                            
                            // When the slider value changes, update the input and span
                            LifeSlider.noUiSlider.on('update', function( values, handle ) {
                            if ( handle ) {
                            valueInput.value = values[handle];
                            } else {
                            valueInput.innerHTML = values[handle];
                            }
                            });
                            
                            // When the input changes, set the slider value
                            valueInput.addEventListener('change', function(){
                            LifeSlider.noUiSlider.set([null, this.value]);
                            });