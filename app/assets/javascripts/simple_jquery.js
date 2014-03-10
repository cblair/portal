
//viz.js

jQuery(function($) {
	$(document).ready(function () {
		$('div#hidden_group > a.btn-inverse').toggle();
		$('div#hidden_group > form').toggle();
		$('div#hidden_group > div.hidden_section').hide();

		//Adds Show/Hide functionality to a hidden for with buttons.
		$('div#hidden_group > a.btn').click(function(e){
			e.preventDefault();
			$(this).parent().children('a.btn').toggle();
			$(this).parent().children('div.hidden_section').fadeToggle();
		});
	});
});