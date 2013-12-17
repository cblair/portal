//Removes a metadata row set. (uses link to function)
//TODO: replace "link to function" with "link to"?
function del_mrow(link) {
  $(link).prev("input[type=hidden]").val("true");
  $(link).closest('fieldset').hide("fast");
}

// Adds metarow (uses link to)
$(document).ready(function() {
  $('.add_fields').click(function(event) {
    time = new Date().getTime()
    regexp = new RegExp($(this).data('id'), 'g')
    $(this).before($(this).data('metarows').replace(regexp, time));
    event.preventDefault();
  });
});
