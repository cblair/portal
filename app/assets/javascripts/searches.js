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
	function updateSearchDatatables() {
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

		//dataTable
		var search_table = $('#search').dataTable({
			"sPaginationType"	: "bootstrap",
			"bJQueryUI"			: true,
			"bProcessing"		: true,
			"bServerSide"		: true,
			"bSort"				: false,
			//Hides search box
			bFilter				: false,
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
	}

	////////////////////////////////////////////////////////////////////////////
	// Main Search stuff
	////////////////////////////////////////////////////////////////////////////	
	function initMainSearch() {
		//Override the search submit with our own function that will do
		// Datatable stuff
		$('form#main-search').submit(updateMainSearch);
	}

	function updateMainSearch(e) {
		e.preventDefault();

		console.log('TS: running main search');
		console.log(e.data);

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
				populateInitialSearch(result);
			},
			error: function(result) {
				$('#error').show();
			}
		});
	}

	function populateInitialSearch(initSearchResults) {
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

		updateSearchDatatables();
	}

	////////////////////////////////////////////////////////////////////////////
	// Search Controller stuff
	////////////////////////////////////////////////////////////////////////////
	function runSearchesControllerJS() {
		//init / update DataTables
		updateSearchDatatables();

		//init other stuff
		initMainSearch();

	} //end runSearchesControllerJS

	$(document).ready(function () {
		if(CONTROLLER_NAME == "searches") {
			runSearchesControllerJS();
		}
	}); 
});