var SEARCH_TABLE;

jQuery(function($) {

	function runDocumentsForCollectionsControllers() {
		$.reloadDocumentDatatable = function ($, collectionid) {
			//change the collection id data in the DOM
			$('.documents_datatable').data('collection-id', collectionid);

			//get new data for the collection id
			SEARCH_TABLE.fnReloadAjax();
		};

		$.extend( $.fn.dataTableExt.oStdClasses, {
			//Taking out for now - URI too long
			//"sSortAsc": "header headerSortDown",
			//"sSortDesc": "header headerSortUp",
			//"sSortable": "header",
			"sWrapper": "dataTables_wrapper form-inline"
		});

		$(document).ready(function () {	
			SEARCH_TABLE = $('.documents_datatable').dataTable({
				"sPaginationType"	: "bootstrap",
				"bJQueryUI"			: true,
				"bProcessing"		: true,
				"bServerSide"		: true,
				//"bSort"				: false,
				//Let's send the collection_id so documents#index can filter  
				"fnServerParams": function ( aoData ) {
	    			aoData.push( 
	    						{ 
	    							"name": "collection_id", 
	    							"value": $(this).data('collection-id') 
	    						} 
	    						);
				},
				//Helps with long URIs
				"sServerMethod"		: "POST",
				//Taking out search
				//"sDom": "<'row'<'span6'l><'span6'f>r>t<'row'<'span6'i><'span6'p>>",
				"sDom": "<'row'<'span6'l><'span6'f>r>t<'row'<'span6'i><'span6'p>>",

				//Source for server-side data
				"sAjaxSource"		: $('.documents_datatable').data('source'),

				"aoColumns": [
								/*name*/ 			null,
								/*validated*/		{ "bSortable": false, "bSearchable" : false},
								/*destroy path*/	{ "bSortable": false, "bSearchable" : false}
							]
			});
		});
	} //end runDocumentsForCollectionsControllers

	if(CONTROLLER_NAME == "collections" || CONTROLLER_NAME == "projects") {
		runDocumentsForCollectionsControllers();
	} 
});