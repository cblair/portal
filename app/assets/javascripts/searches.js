jQuery(function($) {

	function runSearchesControllerJS() {
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
			//dataTable
			var search_table = $('#search').dataTable({
				"sPaginationType"	: "bootstrap",
				"bJQueryUI"			: true,
				"bProcessing"		: true,
				"bServerSide"		: true,
				"bSort"				: false,
				//Helps with long URIs
				//"fnServerParams": "",
				"sServerMethod"		: "POST",
				//Taking out search
				"sDom": "<'row'<'span6'l><'span6'f>r>t<'row'<'span6'i><'span6'p>>",
				"sAjaxSource"		: $('#search').data('source')
			});

			//Do a default search if the data attr is set (probably originally from
			// an HTML param)
			var default_search = $('#search').data('default-search');
			if((default_search != undefined) && (default_search != "")) {
				search_table.fnFilter(default_search);
			}

			//only search on enter keypress 
			$('.dataTables_filter input')
	    		.unbind('keypress keyup')
	    		.bind('keypress keyup', function(e){
	      			if (e.keyCode != 13) return;
	      			search_table.fnFilter($(this).val());
	    		});
		});

	} //end runSearchesControllerJS

	if(CONTROLLER_NAME == "searches") {
		runSearchesControllerJS();
	} 
});