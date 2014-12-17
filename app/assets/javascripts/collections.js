var PARENT_COLLECTION_ID_HASH = {};
var COLLECTION_ELEMENT_WIDTH = undefined;

function get_hash_keys(hash) {
	var keys = new Array();
	for(var i in hash) {
		if (hash.hasOwnProperty(i)) {
			keys.push(i);
		}
	}
	return keys;
}

function get_max_hash_value(hash) {
	var keys = get_hash_keys(hash);
	var max = hash[keys[0]];

	for(var i in keys) {
		key = keys[i];
		if(hash[key] > max) {
			max = hash[key];
		}
	}

	return(max);
}

function get_min_hash_value(hash) {
	var keys = get_hash_keys(hash);
	var min = hash[keys[0]];

	for(var i in keys) {
		key = keys[i];
		if(hash[key] < min) {
			min = hash[key];
		}
	}

	return(min);
}

function count_matching_hash_values(hash, match_val) {
	var count = 0;
	var keys = get_hash_keys(hash);

	for(var i in keys) {
		key = keys[i];
		if(hash[key] == match_val) {
			count += 1;
		}
	}

	return(count);
}

jQuery(function($) {
	///////////////////////////////////////////////////////////////////////////////
	// Tree Nodes showing/hiding
	///////////////////////////////////////////////////////////////////////////////
	
	function updateDocColSubfields(e) {
		e.preventDefault();

		$(this).parent().children('a.col-doc-plus-minus').toggle();
		$(this).parent().parent().children('ul.col-doc-attr-form').toggle();

		$(this).parent().children('span.col-doc-attrs').toggle();		

		$(this).parent().parent().parent().children('ul.col-doc').toggle();

		//update the datatable
		var collectionid = $(this).parent().parent().parent().data('collectionid');

		$('table.documents_datatable').data('collectionid',collectionid);
		$.reloadDocumentDatatable($, collectionid);
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
				//TODO: need to do long polling	
				//setTimeout(updateScaffoldTable, 2000);
			},
			error: function(result) {
				$('#error').show();
			}
		});
	}


	$(document).ready(function () {
		$.initCollectionTree($);
    
    //Help/info popup in show view
    $('#data_import_help').popover({html : true, placement : 'right', trigger : 'click',
      content: function () {
      return $('#data_import_popup').html();
      }
    });

		//Bind upload button
		$("a#new-collection-upload").click(function(e) {
			e.preventDefault();

			$('.modal').show();
		});
	});
});
