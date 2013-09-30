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
	function updateSearchDatatables(searchVal, prevShowSelectVal) {
		if(prevShowSelectVal === undefined) {
			prevShowSelectVal = 10;
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

		var sourceUrl = $('#search').data('source');
		if(searchVal != undefined) {
			sourceUrl += "?search_val='" + searchVal + "'";
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
			"sAjaxSource"		: sourceUrl,
			//We have to set this on the init request per what was set before
			"iDisplayLength" : prevShowSelectVal
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

	function changeSearchIconToRefresh() {
		$('.search-button').removeClass('icon-search')
			.addClass('icon-refresh')
			.addClass('icon-spin');
	}

	function changeRefreshIconToSearch() {
		$('.search-button').removeClass('icon-refresh')
			.removeClass('icon-spin')
			.addClass('icon-search');
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
		urlSource += "?searchval='" + encodeURI(searchVal) + "'";
		$.ajax(urlSource, {
			//data: { data : "div.uploads" },
			cache: false,
			beforeSend: function(result) {

				//Change the search icon to a spinning refresh
				changeSearchIconToRefresh();
			},
			success: function(result) {
				//Fade out the doc-name only alert by default
				$('div.document-name-results-only').fadeOut();

				if(
					(result["colnames"].length === 2)
					&&
					(result["colnames"][0] === "Documents")
				) {
					$('div.document-name-results-only').fadeIn();
				}

				populateInitialSearch(result, searchVal);

				//Change the search icon to a spinning refresh
				changeRefreshIconToSearch();
			},
			error: function(result) {
				$('#error').show();
			}
		});
	}

	function populateInitialSearch(initSearchResults, searchVal) {
		//Get the current value of the "Show" select, so we can reset it in the
		// new table
		var prevShowSelectVal =  $('div#search_length select').val();
		if(prevShowSelectVal === undefined) {
			prevShowSelectVal = 10;
		}

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

		updateSearchDatatables(searchVal, prevShowSelectVal);

		//Reset the Show select value to the previous, just for the display
		$('div#search_length select').val(prevShowSelectVal);
	}

	////////////////////////////////////////////////////////////////////////////
	// Other Search decoration stuff
	////////////////////////////////////////////////////////////////////////////
	function decorateDocPopovers() {
		$('.doc-popover').popover({html : true, trigger : 'hover'});
	}

	////////////////////////////////////////////////////////////////////////////
	// Search Controller stuff
	////////////////////////////////////////////////////////////////////////////
	function runSearchesControllerJS() {
		//init / update DataTables
		updateSearchDatatables(undefined, undefined);

		//init other stuff
		initMainSearch();

	} //end runSearchesControllerJS


	$(document).ready(function () {
		if(
			(CONTROLLER_NAME == "searches")
			|| (CONTROLLER_NAME == "home" && ACTION_NAME == "demo")
		) {
			runSearchesControllerJS();
		}

		//other page decorations
		$('#search-help').tooltip();

	    //decorate popovers on search results
		//We won't know from Datatable's AJAX call when new data is displayed, 
		//so call popover every once in a while.
		setInterval(function() {decorateDocPopovers()}, 1000); //call once a second
	}); 
});