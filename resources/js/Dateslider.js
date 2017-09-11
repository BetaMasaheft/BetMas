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
                        </script>
                    </div>
                    <div class="col-md-3">
                        <div class="col-md-6">
                            <span class="example-val" id="event-start"/>
                        </div>
                        <div class="col-md-6">
                            <span class="example-val" id="event-end"/>
                        </div>
                        <script>
                            var dateValues = [
                            document.getElementById('event-start'),
                            document.getElementById('event-end')
                            ];
                            
                            slider.noUiSlider.on('update', function( values, handle ) {
                            dateValues[handle].innerHTML = values[handle];
                            });
                        </script>
                    </div>
                    <div class="col-md-3">
                        <input id="value-input"/>
                        <script>
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