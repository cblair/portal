///////////////////////////////////////////////////////////////////////////////
// Tree Nodes showing/hiding
///////////////////////////////////////////////////////////////////////////////
jQuery(function($) {
	
	function updateDocColSubfields(e) {
		e.preventDefault();
		
		//$(this).toggle();
		$(this).parent().children('a.col-doc-plus-minus').toggle();
		$(this).parent().parent().children('ul.col-doc-attr-form').toggle();
		$(this).parent().parent().parent().children('ul.col-doc').toggle();
	}
	
	
	$.initCollectionTree = function() {
		var colUl = $('ul.col-doc');
		colUl.children('li').children('ul').toggle();
		colUl.children('li').children('span').children('a#col-doc-minus').toggle();
		colUl.children('ul.col-doc').toggle();
	    
	    colUl.children('li').children('span').children('a.col-doc-plus-minus').click(
	    	updateDocColSubfields
	    );
	}
	
	
	$(document).ready(function () {
		$.initCollectionTree($);
	});
});