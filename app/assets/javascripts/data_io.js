jQuery(function($) {
	function isCollectionSelected() { 
		var collection_selected = $('select#post_collection_id option:selected').text();
		return(collection_selected == "(none)");
	}
	
	$('select#post_collection_id').change(function(){
		if(isCollectionSelected() == true) {
			$('input#post_collection_text').removeAttr('disabled');
		}
		else {
			$('input#post_collection_text').attr('disabled', 'disabled');
		}
	});
});