jQuery(function($) {
	///////////////////////////////////////////////////////////////////////////////
	// Tree Nodes showing/hiding
	///////////////////////////////////////////////////////////////////////////////
	
	function updateDocColSubfields(e) {
		e.preventDefault();
		
		//$(this).toggle();
		$(this).parent().children('a.col-doc-plus-minus').toggle();
		$(this).parent().parent().children('ul.col-doc-attr-form').toggle();

		$(this).parent().children('span.col-doc-attrs').toggle();		

		$(this).parent().parent().parent().children('ul.col-doc').toggle();
	}
	
	
	$.initCollectionTree = function() {
		var colUl = $('ul.col-doc');
		colUl.children('li').children('ul').toggle();
		colUl.children('li').children('span').children('a#col-doc-minus').toggle();

		colUl.children('li').children('span').children('span.col-doc-attrs').toggle();

		colUl.children('ul.col-doc').toggle();
	    
	    colUl.children('li').children('span').children('a.col-doc-plus-minus').click(
	    	updateDocColSubfields
	    );
	}

	function updateScaffoldTableNode(node) {
		var url_str = '/' + CONTROLLER_NAME + '.json';
		
		return;

		if(typeof(CONTROLLER_WHERE) != "undefined") {
			url_str += '?' + CONTROLLER_WHERE;
		}
		
		$.ajax(url_str, {
			//data: { data : "div.uploads" },
			cache: false,
			beforeSend: function(result) {
				//$('div.scaffold table').hide();
			},
			success: function(result) {
				//$('div.scaffold table').after('<p>test</p>');
				if(result != SCAFFOLD_RESULTS) {
					SCAFFOLD_RESULTS = result;
					text = getScaffoldTableText(result);
					
					$('div.scaffold table').remove();
					$('div.scaffold').append(text);
				}
				//TODO: renabled for continued updating, but we need to do long polling	
				//setTimeout(updateScaffoldTable, 2000);
			},
			error: function(result) {
				$('#error').show();
			}
		});
	}
	
	

	$(document).ready(function () {
		$.initCollectionTree($);
	});
});