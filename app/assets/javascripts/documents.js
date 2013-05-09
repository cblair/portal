var SEARCH_TABLE = null;

jQuery(function($) {

	//disables warnings, TODO to fix
	$.fn.dataTableExt.sErrMode = "throw";

	//dataTables
	$.extend( $.fn.dataTableExt.oStdClasses, {
		//Taking out for now - URI too long
		//"sSortAsc": "header headerSortDown",
		//"sSortDesc": "header headerSortUp",
		//"sSortable": "header",
		"sWrapper": "dataTables_wrapper form-inline"
	});

	$.initDocumentDatatable = function ($, data_source) {
		if(data_source == undefined) {
			data_source = $('#documents').data('source');
		}

		//dataTables
		SEARCH_TABLE = $('#documents').dataTable({
			"sPaginationType"	: "bootstrap",
			"bJQueryUI"			: true,
			"bProcessing"		: true,
			"bServerSide"		: true,
			"bSort"				: false,
			//Helps with long URIs
			//"fnServerParams": "",
			"sServerMethod"		: "POST",
			//Taking out search
			//"sDom": "<'row'<'span6'l><'span6'f>r>t<'row'<'span6'i><'span6'p>>",
			"sDom": "<'row'<'span6'l><'span6'f>r>t<'row'<'span6'i><'span6'p>>",
			"sAjaxSource"		: data_source
		});

		//only search on enter keypress 
		$('.dataTables_filter input')
    		.unbind('keypress keyup')
    		.bind('keypress keyup', function(e){
      			if (e.keyCode != 13) return;
      			SEARCH_TABLE.fnFilter($(this).val());
    		}
    	);
	};

	$(document).ready(function () {
		$.initDocumentDatatable($);
	});
});