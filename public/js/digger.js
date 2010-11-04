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
            $.get('/q/' + query, {} , function(data) {
                    $('#result').html(data);
            });
//            alert("done");
            return false;
    });
});

