jQuery(function($) {
	//Add a format function to String
	String.prototype.format = function() {
	  var args = arguments;
	  return this.replace(/{(\d+)}/g, function(match, number) { 
	    return typeof args[number] != 'undefined'
	      ? args[number]
	      : match
	    ;
	  });
	};

	////////////////////////////////////////////////////////////////////////////
	// Datatable stuff
	////////////////////////////////////////////////////////////////////////////
	function updateSearchDatatables(searchVal) {
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

		var sourceUrl = $('#search').data('source');
		if(searchVal != undefined) {
			sourceUrl += "?search_val=" + searchVal;
		}

		//dataTable
		var search_table = $('#search').dataTable({
			"sPaginationType"	: "bootstrap",
			"bJQueryUI"			: true,
			"bProcessing"		: true,
			"bServerSide"		: true,
			"bSort"				: false,
			//Hides search box
			"bFilter"			: false,
			//Helps with long URIs
			//"fnServerParams": "",
			"sServerMethod"		: "POST",
			//Taking out search
			"sDom": "<'row'<'span6'l><'span6'f>r>t<'row'<'span6'i><'span6'p>>",
			"sAjaxSource"		: sourceUrl
		});

		//only search on enter keypress 
		$('.dataTables_filter input')
    		.unbind('keypress keyup')
    		.bind('keypress keyup', function(e){
      			if (e.keyCode != 13) return;
      			search_table.fnFilter($(this).val());
    		});

    	if(searchVal != undefined) {
	    	//Call search to filter from our initial search val
    		search_table.fnFilter(searchVal);
    	}
	}

	////////////////////////////////////////////////////////////////////////////
	// Main Search stuff
	////////////////////////////////////////////////////////////////////////////	
	function initMainSearch() {
		//Hide our "Document results only" alert for now
		$('div.document-name-results-only').hide();

		//Override the search submit with our own function that will do
		// Datatable stuff
		$('form#main-search').submit(updateMainSearch);
	}

	function updateMainSearch(e) {
		e.preventDefault();

		//Get our search result container
		var mainSearchResults = $('#main-search-results');

		//Get the current search val
		var searchVal = $('input#main-search').val();

		var initDataSource = mainSearchResults.data('init-source');
		runInitialSearch(initDataSource, searchVal);
	}

	//This function does the initial search, so we can find out what document
	// match
	function runInitialSearch(urlSource, searchVal) {
		urlSource += "?searchval=" + searchVal;
		$.ajax(urlSource, {
			//data: { data : "div.uploads" },
			cache: false,
			beforeSend: function(result) {
				//$('div.scaffold table').hide();
			},
			success: function(result) {
				//Fade out the doc-name only alert by default
				$('div.document-name-results-only').fadeOut();

				//If the colnames are only "Documents", display our doc-name only alert
				console.log(result["colnames"]);
				console.log(result["colnames"] === ["Documents"]);
				if(
					(result["colnames"].length === 1)
					&&
					(result["colnames"][0] === "Documents")
				) {
					$('div.document-name-results-only').fadeIn();
				}

				populateInitialSearch(result, searchVal);
			},
			error: function(result) {
				$('#error').show();
			}
		});
	}

	function populateInitialSearch(initSearchResults, searchVal) {
		//Get our search result container
		var mainSearchResults = $('#main-search-results');

		//Get the data source and default search variables
		var initDataSource = mainSearchResults.data('init-source');
		var dataSource = mainSearchResults.data('source');
		var defaultSearch = mainSearchResults.data('default-search');

		//Get the data columns that match
		var dataColumnHtml = "";
		var dataColumnNames = initSearchResults["colnames"];
		for(i in dataColumnNames) {
			dataColumnName = dataColumnNames[i];
			dataColumnHtml += "<td>" + dataColumnName + "</td>\n";
		}

		//Get our search table html template, and format it with our data
		var searchTableTemplate = $('#searchTableTemplate').html();
		var searchTableTemplateString = searchTableTemplate.format(
			dataSource, 
			defaultSearch,
			dataColumnHtml
		);

		//If a Datatable exists, just blow it away
		$('#main-search-results div.datatable-container').remove();

		//Add the search datatable to our results container
		mainSearchResults.append(searchTableTemplateString);
		//TODO: if search criteria empty, hide
		mainSearchResults.fadeIn();

		updateSearchDatatables(searchVal);
	}

	////////////////////////////////////////////////////////////////////////////
	// Search Controller stuff
	////////////////////////////////////////////////////////////////////////////
	function runSearchesControllerJS() {
		//init / update DataTables
		updateSearchDatatables(undefined);

		//init other stuff
		initMainSearch();

	} //end runSearchesControllerJS

	$(document).ready(function () {
		if(CONTROLLER_NAME == "searches") {
			runSearchesControllerJS();
		}
	}); 
});