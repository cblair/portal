jQuery(function($) {

	$.extend( $.fn.dataTableExt.oStdClasses, {
		"sWrapper": "dataTables_wrapper form-inline"
	});

	$(document).ready(function () {	
		$('#documents').dataTable({
			"sPaginationType"	: "bootstrap",
			"bJQueryUI"			: true,
			"bProcessing"		: true,
			"bServerSide"		: true,
			"bSort"				: false,
			//Disabling search
			//"sDom": "<'row'<'span6'l><'span6'f>r>t<'row'<'span6'i><'span6'p>>",
			"sDom": "<'row'<'span6'l><'span6'>r>t<'row'<'span6'i><'span6'p>>",
			"sAjaxSource"		: $('#documents').data('source')
		});
	});
});