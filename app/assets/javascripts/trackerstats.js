/*jslint sloppy: true, white: true, plusplus: true, maxerr: 50, indent: 4 */
var TimeTracker;
TimeTracker = {
    props: {},
    set_property: function(name, value){
        this.props[name] = value;
    },
    get_property: function(name){
        return this.props[name];
    }
};

TimeTracker.add_datepicker = function (selector, value){
    this.overlay = null;
    var overlayId = 'TimeTracker_datepicker_overlay',
        that = this;
    $(selector).datepicker({
        dateFormat: "yy/mm/dd",
        beforeShow: function(){
            if (!that.overlay){
                $('body').append('<div id="' + overlayId + '" style="z-index: 0; position: fixed; top: 0; left: 0; width: 100%; height: 100%; opacity: 0"/>');
                that.overlay = $('#' + overlayId);
            }
            that.overlay.show();
            return true;
        },
        onClose: function(dateText, inst){
            that.overlay.hide();
            return true;
        }
    }).val(value);
};

TimeTracker.setup_iterations_slider = function(slider_sel, start_sel, finish_sel){
    var iterations = this.get_property("iterations") || [],
      start_val = 0, end_val = iterations.length - 1, date, i;

    date = $(start_sel).val();
    if (date !== ""){
        i = iterations.length;
        while(i--){
            if (iterations[i] <= date){
                start_val = i;
                break;
            }
        }
    }

    date = $(finish_sel).val();
    if (date !== ""){
        i = iterations.length;
        while(i--){
            if (iterations[i] < date){
                end_val = i;
                break;
            }
        }
    }

    $(slider_sel).slider({
        range: true,
        min: 0,
        max: iterations.length - 1,
        values: [start_val, end_val],
        change: function(event, ui){
            var idx = $(this).slider("values", 0);
            $(start_sel).val(iterations[idx]);

            idx = $(this).slider("values", 1) + 1;
            $(finish_sel).val(iterations[idx]);
        }
    });
};
