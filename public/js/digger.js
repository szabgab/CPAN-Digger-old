$(function(){
    $("#dialog").dialog({
					autoOpen: false,
    buttons: {
        'button 1': function() {
                alert(1);
                // handle if button 1 is clicked
        },
        'button 2': function() {
                alert(2);
                // handle if button 2 is clicked
        },
        'button 3': function() {
                alert(3);
                // handle if button 3 is clicked
        }
    }
    });

    $('#dialog_link').click(function(){
	$('#dialog').dialog('open');
	return false;
    });

    $('#dig').click(function() {
            var query = $('#query').val();
            $.get('/q/' + query, {} , function(resp) {
                    $('#content').hide();
                    $('#result').html(resp);
                    //alert('hello');
                    //var dx = new Array;
                    var dx = {a: 23, b:12};
                    alert(1);
                    //dx[0] = "first";
                    //dx["abc"] = "sec";
                    //alert(dx[0]);
                    //alert(dx["abc"]);
                    //var data = eval("{yxx: 23}");
                    //var data = eval(resp);
//                    $('#ellapsed_time').html(resp.ellapsed_time);
                    //alert(data["ellapsed_time"]);
                    //alert(data[0]);
                    alert(dx.length);
            });
//            alert("done");
            return false;
    });
});

