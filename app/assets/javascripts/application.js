// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs
//= require jquery.ui.all
//= require jquery.modal

// require jquery-fileupload/basic
// require jquery-fileupload/vendor/tmpl
//= require jquery-fileupload

//= require dataTables/jquery.dataTables
/// require dataTables/jquery.dataTables.bootstrap
//= require dataTables/jquery.dataTables.api.fnReloadAjax

//= require d3
//  require d3.layout
//  require d3.v3.min.js // or, alternatively-named, d3.min.js

//= require angular

//Include only specific js files individually.
// To see what is being loaded, use this parameter:
// ?debug_assets=1
//
// require_tree .

//= require charts
//= require collections
//= require data_io

//= require feeds
//= require ifilters
//= require live_scaffolds
//= require paging
//= require uploads
//= require simple_jquery
//= require jobs
//= require home_datatable_example
//= require documents
//= require documents_for_collections
//= require searches
//= require metaforms
//= require jquery.tabletojson

//= require foundation

jQuery.ajaxSetup({ 
  'beforeSend': function(xhr) {xhr.setRequestHeader("Accept", "text/javascript")} 
});

$(function(){ $(document).foundation(); });
