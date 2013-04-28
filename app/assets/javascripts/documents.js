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

	$(document).ready(function () {

		//dataTables
		var search_table = $('#documents').dataTable({
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
			"sAjaxSource"		: $('#documents').data('source')
		});

		//only search on enter keypress 
		$('.dataTables_filter input')
    		.unbind('keypress keyup')
    		.bind('keypress keyup', function(e){
      			if (e.keyCode != 13) return;
      			search_table.fnFilter($(this).val());
    		});
	});
});