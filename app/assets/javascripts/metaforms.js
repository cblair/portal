//Removes a metadata row set. KEEP (uses link to function)
//TODO: replace "link to function" with "link to"?
function del_mrow(link) {
  //console.log(link);
  $(link).prev("input[type=hidden]").val = "1";
  //$(link).closest('.mrow').hide("fast");
  $(link).closest('fieldset').remove();
}

// Adds/removes metarow KEEP (uses link to)
$(document).ready(function() {
/*
  $('.remove_fields').click(function(event) {
    console.log("remove");
    $(this).prev('input[type=hidden]').val('1')
    //$(this).closest('.mrow').remove();
    $(this).closest('fieldset').hide("fast");
    event.preventDefault()
  });
*/
  $('.add_fields').click(function(event) {
    console.log("add");
    time = new Date().getTime()
    console.log(time);
    regexp = new RegExp($(this).data('id'), 'g')
    console.log(regexp);
    $(this).before($(this).data('metarows').replace(regexp, time))
    //$(this).before($(this).data('fields'))
    event.preventDefault()
  });
});
