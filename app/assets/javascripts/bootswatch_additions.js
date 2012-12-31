//Some extra Bootswatch sauce

//Progress bars for document uploads
//hide by default
function updateProgressBar() {
	$.ajax('/tests/index.json', {
		data: { data : "div.test" },
		cache: false,
		beforeSend: function(result) {
			$('#error').hide();
		},
		success: function(result) {
			var progress = result['val'];
			$('div.progress').remove();
			var text = '<div class="progress progress-striped active">\n';
	        text += '<div class="bar" style="width:'
	        text += progress;
	        text += '%;"></div>\n';
	      	text += '</div>';
			$('ul.document li.span4').after(text);
			
			//re-register if things didn't complete
			if(progress < 100) {
				setTimeout(updateProgressBar, 200);
			}
			else {
				$('div.progress').fadeOut();
			}
		},
		error: function(result) {
			$('#error').show();
		}
	});
}

jQuery(function($) {
	//Notification stuff
	//$('div.alert').fadeOut(8000);
	
	//Document explorer - progress bars
	//setTimeout(updateProgressBar, 200);
});