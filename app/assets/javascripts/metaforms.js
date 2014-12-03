//Removes a metadata row set. (uses link to function)
//TODO: replace "link to function" with "link to"?
function del_mrow(link) {
  $(link).prev("input[type=hidden]").val("true");
  $(link).closest('fieldset').hide("fast");
}

$(document).ready(function() {

  // Adds metarow (uses link to)
  $('.add_fields').click(function(event) {
    time = new Date().getTime()
    regexp = new RegExp($(this).data('id'), 'g')
    $(this).before($(this).data('metarows').replace(regexp, time));
    event.preventDefault();
  });
  
  //Makes metadata rows in metaform show view sortable
  $( "#mf_sortable" ).sortable({ 
    placeholder: "ui-state-highlight",
    axis: "y",
    update: function(e, ui) {
      $.post( $(this).data("update-url"), $(this).sortable("serialize") )
    }
  });
  $( "#mf_sortable" ).disableSelection();
});
