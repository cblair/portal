var DOCUMENTS_SEARCH_TABLE = null;

//Poll every 5 seconds.
var JOB_DATA_POLL_INTERVAL = 5000;

jQuery(function($) {

	function runDocumentsControllerJS() {
		//enable tooltip
		$('.job-label').popover({html : true, trigger : 'hover'});

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
			DOCUMENTS_SEARCH_TABLE = $('#documents').dataTable({
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

			//Do a default search if the data attr is set (probably originally from
			// an HTML param)
			var default_search = $('#documents').data('default-search');
			if((default_search != undefined) && (default_search != "")) {
				DOCUMENTS_SEARCH_TABLE.fnFilter(default_search);
			}

			//only search on enter keypress 
			$('.dataTables_filter input')
	    		.unbind('keypress keyup')
	    		.bind('keypress keyup', function(e){
	      			if (e.keyCode != 13) return;
	      			DOCUMENTS_SEARCH_TABLE.fnFilter($(this).val());
	    		}
	    	);
		};

		$(document).ready(function () {
			$.initDocumentDatatable($);

			setInterval(function() {pollForJobData()}, JOB_DATA_POLL_INTERVAL); //call once every job polling interval
		});
	} //end runDocumentsControllerJS


	//Polling for job status for the document. Polling sucks, but we
	// don't have long polling put together yet.
	function pollForJobData() {
		var jobDisplay = $('div#doc_job_display');
		var urlSource = jobDisplay.data('show-simple-json-source');

		$.ajax(urlSource, {
			//data: { data : "div.uploads" },
			cache: false,
			beforeSend: function(result) {

			},
			success: function(result) {
				var jobID = result["job_id"];
				if(jobID) {

					//Change the job label stuff to show we know what's going on.
					if(result['job_waiting'] === true) {
						$('span.job-status-text').text('Job Waiting...');
						$('a#job-label i').attr('class', 'icon-refresh icon-spin icon-white');
					}
					if(result['job_started'] === true) {
						$('span.job-status-text').text('Job Processing...');
						$('a#job-label i').attr('class', 'icon-cog icon-spin icon-white');
					}
					if(result['job_succeeded'] === true) {
						$('span.job-status-text').text('Job Completed');
						$('a#job-label i').attr('class', 'icon-check icon-white');
						$('a#job-label').attr('class', 'label job-label label-success');
						$('a#job-label').attr('class', 'label job-label label-success');

						//Update the popover content.
						var jobPopover = $('a#job-label');
						jobPopover.attr("data-content", '<p>' + result['job_error_or_output'] + '</p>');
						jobPopover.attr('data-original-title', 'Job Output');

						$('a#job-label').prop("href", '/jobs/' + jobID);
					}

					//
					jobDisplay.fadeIn();
				}
			},
			error: function(result) {
				$('#error').show();
			},
			//timeout after our polling interval
			timeout: JOB_DATA_POLL_INTERVAL
		});
	}

	if(CONTROLLER_NAME == "documents") {
		runDocumentsControllerJS();
	} 
});