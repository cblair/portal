var IFILTER_HEADER_FORM_ELEMENTS = 0;

function addClickEventToRemoveButtons() {
	$('a.remove-ifilter-header').bind({
		click: removeIfilterHeaderFormElement
	});
}

function addIfilterHeaderFormElement(e) {
	e.preventDefault();
	
	var text = 	'<tr>';
	text += 	' <td><input id="ifilter_headers" name="ifilter_headers[' + IFILTER_HEADER_FORM_ELEMENTS + ']" size="30" type="text" /></td>';
	text += 	' <td><a href="#" class="btn btn-primary remove-ifilter-header">- Remove</a></td>';
	text += 	'</tr>';
	
	$(this).parent().parent().before(text);
	
	//bind a click event for removing
	addClickEventToRemoveButtons();
	
	IFILTER_HEADER_FORM_ELEMENTS++;
};

function removeIfilterHeaderFormElement(e) {
	e.preventDefault();
	
	//tr
	// td
	//  a
	$(this).parent().parent().hide();
};

jQuery(function($) {
	$('a.add-ifilter-header').bind({
		click: addIfilterHeaderFormElement
	});
	
	addClickEventToRemoveButtons();
});