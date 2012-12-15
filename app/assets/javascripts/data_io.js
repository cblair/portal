jQuery(function($) {
	var collection_selected = $('tr#collection_id select option:selected').text();
	var is_none_collection = (collection_selected == "(none)");

	if(is_none_collection != true) {
		$('tr#collection_text').hide();
	}
	
	$('input#collection_id select').change(function(){
		collection_selected = $('tr#collection_id select option:selected').text();
		is_none_collection = (collection_selected == "(none)");
		
		if(is_none_collection == true) {
			$('input#collection_text').show();
		}
		else {
			$('input#collection_text').hide();
		}
	});
});