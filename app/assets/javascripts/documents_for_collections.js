jQuery(function($) {

	$.extend( $.fn.dataTableExt.oStdClasses, {
		//Taking out for now - URI too long
		//"sSortAsc": "header headerSortDown",
		//"sSortDesc": "header headerSortUp",
		//"sSortable": "header",
		"sWrapper": "dataTables_wrapper form-inline"
	});

	$(document).ready(function () {	
		$('#documents').dataTable({
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
    							"value": $('#documents').data('collection-id') 
    						} 
    						);
			},
			//Helps with long URIs
			"sServerMethod"		: "POST",
			//Taking out search
			//"sDom": "<'row'<'span6'l><'span6'f>r>t<'row'<'span6'i><'span6'p>>",
			"sDom": "<'row'<'span6'l><'span6'f>r>t<'row'<'span6'i><'span6'p>>",
			"sAjaxSource"		: $('#documents').data('source'),

			"aoColumns": [
							/*name*/ 		null,
							/*show path*/ 	{ "bSortable": false, "bSearchable" : false},
							/*edit path*/	{ "bSortable": false, "bSearchable" : false}
						]
		});
	});
});