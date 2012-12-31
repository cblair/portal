
//viz.js

jQuery(function($) {
	$(document).ready(function () {
		$('div#hidden_form > a.btn-inverse').toggle();
		$('div#hidden_form > form').toggle();

		$('div#hidden_form > a.btn').click(function(e){
			e.preventDefault();
			$(this).parent().children('a.btn').toggle();
			$(this).parent().children('form').fadeToggle();
		});
	});
});