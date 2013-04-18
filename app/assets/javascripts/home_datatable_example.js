
jQuery(function($) {

	$.extend( $.fn.dataTableExt.oStdClasses, {
		//Taking out for now - URI too long
		"sSortAsc": "header headerSortDown",
		"sSortDesc": "header headerSortUp",
		"sSortable": "header",
		"sWrapper": "dataTables_wrapper form-inline"
	});

	$(document).ready(function () {	

		$('#documents').dataTable({
			"sPaginationType"	: "bootstrap",
			"bJQueryUI"			: true,
			"bProcessing"		: true,
			//"bServerSide"		: true,
			//"bSort"				: false,
			//Helps with long URIs
			//"fnServerParams": "",
			"sServerMethod"		: "POST",
			//Taking out search
			//"sDom": "<'row'<'span6'l><'span6'f>r>t<'row'<'span6'i><'span6'p>>",
			"sDom": "<'row'<'span6'l><'span6'f>r>t<'row'<'span6'i><'span6'p>>"
			//"sAjaxSource"		: $('#documents').data('source')
		});
	});

	$(document).ready(function () {	

		$('#search_demo_documents').dataTable({
			"sPaginationType"	: "bootstrap",
			"bJQueryUI"			: true,
			"bProcessing"		: true,
			//"bServerSide"		: true,
			//"bSort"				: false,
			//Helps with long URIs
			//"fnServerParams": "",
			"sServerMethod"		: "POST",
			//Taking out search
			//"sDom": "<'row'<'span6'l><'span6'f>r>t<'row'<'span6'i><'span6'p>>",
			"sDom": "<'row'<'span6'l><'span6'f>r>t<'row'<'span6'i><'span6'p>>"
			//"sAjaxSource"		: $('#documents').data('source')
		});
	});
});