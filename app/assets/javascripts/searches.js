jQuery(function($) {

	var IS_MERGE_SEARCH = false;

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

		//Add the search value
		if(searchVal != undefined) {
			sourceUrl += "?search_val='" + searchVal + "'";
		}

		//Add the merge search option
		sourceUrl += "&" + getMergeButtonParams();

		//Add the doc search pagination options
		sourceUrl += "&" + getActivePaginateParams();
		sourceUrl += "&" + getSearchLengthParams();

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

    	//TODO: don't think we need this anymore
    	/*
    	if(searchVal != undefined) {
	    	//Call search to filter from our initial search val
    		search_table.fnFilter(searchVal);
    	}
    	*/	
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
		//Hide our alerts for now
		$('div.document-name-results-only').hide();
		$('div.search-alert-other').hide();

		//Override the search submit with our own function that will do
		// Datatable stuff
		$('form#main-search').submit(updateMainSearch);

		$(".merge-button").on("click", updateMergeSearch);
	}

	//Sets our merge search option, and then just call updateMainSearch
	function updateMergeSearch(e) {
		//Set merge option in the DOM. Setting variables here will be 
		// ignored in out actually even callbacks/ajax calls.
		$('.merge-button').data('enabled', 'true');

		//Get the last document search params we need, so that merge search
		// will merge the documents in this view
		updateDocSearchStashedData();

		updateMainSearch(e);
	}

	//Return the merge search params string per the value we've stored in
	// the DOM.
	function getMergeButtonParams () {
		if($('.merge-button').data('enabled') === "true") {
			return("merge_search=true");
		} else {
			return("merge_search=false");
		}
	}

	function getActivePaginateParams() {
		var activePaginate = $('button.merge-button').data('document-active-paginate');
		if(activePaginate === null) {
			activePaginate = "''";
		}

		return("active_paginate=" + activePaginate);
	}

	function getSearchLengthParams() {
		var searchLength = $('button.merge-button').data('document-active-search-length');
		if(searchLength === null) {
			searchLength = "''";
		}

		return("search_length=" + searchLength);
	}

	//Shows the pending search alert if the search hasn't yet completed.
	function updatePendingSearchAlert() {
		if($('div.search-alert-pending').data('search-completed') === "false")
		{
			console.log("TS161");
			$('div.search-alert-pending').fadeIn();
		}
	}

	function updateDocSearchStashedData() {
		var activePaginate = $('div.dataTables_paginate ul li.active').text();
		var searchLength = $('div#search_length select option:selected').val();
		$('button.merge-button').data('document-active-paginate', activePaginate);
		$('button.merge-button').data('document-active-search-length', searchLength);
		console.log('TS171');
		console.log($('button.merge-button').data('document-active-paginate'));
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
		var searchParams = "?searchval='" + encodeURI(searchVal) + "'";
		//Add the merge search option
		searchParams += "&" + getMergeButtonParams();

		//Add the doc search pagination options
		searchParams += "&" + getActivePaginateParams();
		searchParams += "&" + getSearchLengthParams();

		urlSource += searchParams;

		//Reset search completed to false for pending search.
		$('div.search-alert-pending').data('search-completed', 'false');
		// ~and set a callback to show the alert after 5 seconds.
		setTimeout(updatePendingSearchAlert, 5000);

		$.ajax(urlSource, {
			//data: { data : "div.uploads" },
			cache: false,
			beforeSend: function(result) {

				//Change the search icon to a spinning refresh
				changeSearchIconToRefresh();
			},
			success: function(result) {
				//Fade out the alerts by default
				$('div.document-name-results-only').fadeOut();
				$('div.search-alert-other').fadeOut();

				if(
					(result["colnames"].length === 2)
					&&
					(result["colnames"][0] === "Documents")
					&&
					(getMergeButtonParams() === "merge_search=true")
				) {
					$('div.document-name-results-only').fadeIn();
				} else if (getMergeButtonParams() === "merge_search=true") {
					//Update alert content
					$('div.search-alert-other p').text("Column names in common for merged documents: " + result["colnames"].join(', '));

					//Other link overrides
					$('button.save-doc-from-search-button').on("click", function(e) {
						e.preventDefault();

						var saveDocUrl = $(this).data('source-url') + searchParams;

						window.location = saveDocUrl;
					});

					//Fade in alert
					$('div.search-alert-other').fadeIn();
				}

				populateInitialSearch(result, searchVal);

				//Change the search icon to a spinning refresh
				changeRefreshIconToSearch();

				//Clear the merge button option, in case the main 
				// search button is the next to be pressed
				$('.merge-button').data('enabled', 'false');

				// Set search completed to true for pending search, in case updatePendingSearchAlert hasn't
				// fired yet.
				$('div.search-alert-pending').data('search-completed', 'true');
				// ~and hide the pending search alert, in case updatePendingSearchAlert has already
				// fired.
				$('div.search-alert-pending').fadeOut();

				//If there were unviewabled documents, display their option in case
				// the user wants to request access.
				console.log("TS259");
				console.log(result["unviewable_doc_ids"]);
				if(result['unviewable_doc_ids']) {
					console.log("TS260");
				}
			},
			error: function(result) {
				$('#error').show();
			},
			//timeout after a minute
			timeout: 60000
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

		//init other search stuff
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