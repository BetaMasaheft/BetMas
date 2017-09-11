       
        // http://stackoverflow.com/questions/16593222/disable-submit-button-unless-original-form-data-has-changed
        var button = $('#submit-data');
        var orig = [];
        
        $.fn.getType = function () {
        return this[0].tagName == "INPUT" ? $(this[0]).attr("type").toLowerCase() : this[0].tagName.toLowerCase();
        }
        
        $("form :input").each(function () {
        var type = $(this).getType();
        var tmp = {
        'type': type,
        'value': $(this).val()
        };
        if (type == 'radio') {
        tmp.checked = $(this).is(':checked');
        }
        orig[$(this).attr('id')] = tmp;
        });
        
        $('form').bind('change keyup', function () {
        
        var disable = true;
        $("form :input").each(function () {
        var type = $(this).getType();
        var id = $(this).attr('id');
        
        if (type == 'text' || type == 'select') {
        disable = (orig[id].value == $(this).val());
        } else if (type == 'radio') {
        disable = (orig[id].checked == $(this).is(':checked'));
        }
        
        if (!disable) {
        return false; // break out of loop
        }
        });
        
        button.prop('disabled', disable);
        });