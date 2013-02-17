// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs

//TODO: I don't know why application.js isn't including this, but this following doesn't work
//= require jquery-fileupload

//= require jquery-ui

//= require jquery-fileupload/basic
//= require jquery-fileupload/vendor/tmpl

//= require highcharts
//= require twitter/bootstrap
//= require dataTables/jquery.dataTables
//= require dataTables/jquery.dataTables.bootstrap
// require_tree .
//= require charts
//= require collections
//= require data_io

//Include for Documents only
// require documents

//= require exporting
//= require feeds
//= require ifilters
//= require live_scaffolds
//= require paging
//= require uploads
//= require viz

jQuery.ajaxSetup({ 
  'beforeSend': function(xhr) {xhr.setRequestHeader("Accept", "text/javascript")} 
})
