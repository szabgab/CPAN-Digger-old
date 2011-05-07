$(document).ready(function() {
    var $dlg = $('<div></div>')
         .html('Hello world')
         .dialog({
               autoOpen: false,
               title: 'Basic dialog',
               closeOnEscape: true,
		modal: true,
               resizable: true,
         });

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

    $('#tryme').click(function(){
            alert("xxx");
    });
    
    $('#dialog_link').click(function(){
	$('#dialog').dialog('open');
	return false;
    });

     $('.keyword').click(function() {
        //alert('Show popup with explanation about ' + this.firstChild.innerHTML);
        $dlg.dialog("option", "title", this.firstChild.innerHTML);
        $dlg.dialog('open');
	return false;
     });

     $('#dig').click(function() {
            var query = $('#query').val();
            //alert($('#what').val());
            var what = $('#what').val();
            $.get('q/' + query + '/' + what, function(resp) {
                    $('#content').hide();
                    if (resp["error"]) {
                       alert(resp["error"]);
                    } else {
//alert(resp);
//                     $('#result').html('ok');
                       var html = '';
                       for (var i=0; i<resp.length; i++) {
                           // distribution
                           if (resp[i]["type"] == 'd') {
                                html += '<div class="author"><a href="http://search.cpan.org/~' + resp[i]["author"]   + '">' + resp[i]["author"] + '</a></div>';
                                html += '<div class="name"><a href="http://search.cpan.org/dist/' + resp[i]["name"] + '">' + resp[i]["name"]   + '</a></div>';
                                html += '<div class="version">' + resp[i]["version"] + '</div>';
                           }
                           // author
                           if (resp[i]["type"] == 'a') {
                                var name = resp[i]["asciiname"];
                                if (resp[i]["name"]) {
                                        name = resp[i]["name"];
                                }
                                html += '<div class="name"><a href="http://search.cpan.org/~' + resp[i]["pauseid"] + '">' + resp[i]["pauseid"] + '(' + name + ')' + '</a></div>';
                                if (resp[i]["homepage"]) {
                                        html += '<div class="name"><a href="' + resp[i]["homepage"] + '">' + resp[i]["homepage"]   + '</a></div>';
                                }
                           }
                          
                           html += '<br>';
                       }
                       $('#result').html(html);
                    }
                    if (resp["ellapsed_time"]) {
                        $('#ellapsed_time').html(resp.ellapsed_time);
                    }
            }, 'json');
            return false;
    });
});

