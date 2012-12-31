//mockups
jQuery(function($) {
	var text = '<div class="progress progress-striped active">\n';
	text += '<div class="bar" style="width:'
	text += "30"
	text += '%;"></div>\n';
	text += '</div>';
	$('ul#827 li.span4').after(text);
	
		var text = '<div class="progress progress-striped active">\n';
	text += '<div class="bar" style="width:'
	text += "0"
	text += '%;"></div>\n';
	text += '</div>';
	//$('ul.document li.span4').after(text);
	$('ul#823 li.span4').after(text);
	$('ul#824 li.span4').after(text);
	$('ul#825 li.span4').after(text);
	$('ul#826 li.span4').after(text);
	
	
	//IFilter
	$('span.header-filter-none').after('<span class="label label-success">Success</span>');
});