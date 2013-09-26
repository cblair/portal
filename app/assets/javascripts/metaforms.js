/*
//Removes a metadata row
function del_mrow(link) {
  //console.log(link);
  //$(link).prev("input[type=hidden]").val = "1";
  $(link).closest('.mrow').hide("fast");
}
*/
/*
function add_mrow(link){
  var rtmp = $(link).parent().find('.mrow').last() //finds last row
  //$(rtmp).append('.mrow');
  //console.log(rtmp);
  $(rtmp).clone().appendTo('.mrow');
}
*/
/*
function add_(link, association, content) {
        var new_id = new Date().getTime();
        var regexp = new RegExp("new_" + association, "g");
        $(link).parent().before(content.replace(regexp, new_id));
}
*/
/*
//BAD: triggers save
$(document).ready(function(){
  $("#hide").click(function(){
    $(".mrow").hide();
  });
});
*/
/*
$(document).ready(function(){
  $("#rtest").on("click",function(){
    alert($(this).text("bye") );
    //$(".mrows").hide();
    //$(this).hide();
  });
});
*/
/*
$(document).ready(function(){
  $("#rtest").on("click", function() {
    alert('Hello, world!');
  });
});
*/
