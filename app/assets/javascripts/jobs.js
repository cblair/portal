var JOBS_SEARCH_TABLE = null;

/*
jQuery.ajaxSetup({ 
	'beforeSend': function(xhr) {
					xhr.setRequestHeader("Accept", "text/javascript");
					xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
					}
})
*/

jQuery(function($) {

	function runJobsControllerJS() {
		function clearJobs(clearJobUrl, docIds) {

			$.ajax({
				type: 'POST',
				beforeSend: function(xhr){
		        xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
		    	},
				url: clearJobUrl,
				//data: {_method:'delete'},
				data: {"doc_ids" : docIds},
				success: null,
				dataType: "json"
			});
				
			return(false);
		}

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
			JOBS_SEARCH_TABLE = $('#jobs').dataTable({
				"sPaginationType"	: "bootstrap",
				"bJQueryUI"			: true,
				"bProcessing"		: true,
				"bServerSide"		: true,
				"bSort"				: true,
				//Helps with long URIs
				//"fnServerParams": "",
				//"sServerMethod"		: "POST",
				"sDom": "<'row'<'span6'l><'span6'f>r>t<'row'<'span6'i><'span6'p>>",
				"sAjaxSource"		: $('#jobs').data('source')
			});

			//Do a default search if the data attr is set (probably originally from
			// an HTML param)
			var default_search = $('#jobs').data('default-search');
			if((default_search != undefined) && (default_search != "")) {
				JOBS_SEARCH_TABLE.fnFilter(default_search);
			}

			//only search on enter keypress 
			$('.dataTables_filter input')
	    		.unbind('keypress keyup')
	    		.bind('keypress keyup', function(e) {
	      			if (e.keyCode != 13) return;
	      			JOBS_SEARCH_TABLE.fnFilter($(this).val());
	    		});

	    	//Clear selected jobs
	    	$("a.clear-jobs").bind("click", function(e) {
	    		//This gets currently filtered data
	    		var linkTextArray = JOBS_SEARCH_TABLE._($('tr td.sorting_1'), {"filter":"applied"});
	    		//This is as far as we can go for nodes; we now have
	    		// the html text for the link.

	    		//Get clear job url
	    		var clearJobUrl = $('div.clear-jobs').data('clear-jobs-source');

	    		//Match doc id in link text with regex
	    		//var docIdsStr = "?";
	    		var docIds = [];

				var re = new RegExp('>([0-9]+)<');

				for(i in linkTextArray) {
					var linkText = linkTextArray[i];
					var m = re.exec(linkText);
					if (m != null) {
						//Grab the first real match, hopefully is only one.
						//docIdsStr += "&docids=" + m[1];
						docIds.push(m[1]);
				  	}
				}

				clearJobs(clearJobUrl, docIds);

				//get new data for the job table
				JOBS_SEARCH_TABLE.fnReloadAjax();
	    	});
		});

	} //end runJobsControllerJS

	if(CONTROLLER_NAME == "jobs") {
		runJobsControllerJS();
	} 
});