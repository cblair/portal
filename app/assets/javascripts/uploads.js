$(document).ready(function() {

  $('#uploads_tbl').dataTable({
    sPaginationType: "full_numbers",
    bJQueryUI: true,
    bProcessing: true,
    bServerSide: true,
    "sDom": "<'row'<'span6'l><'span6'f>r>t<'row'<'span6'i><'span6'p>>",
    "aoColumns": [
      null, //name
      null, //size
      null, //type
      { "bSortable": false } //action
    ],
    sAjaxSource: $('#uploads_tbl').data('source')
  });

});
