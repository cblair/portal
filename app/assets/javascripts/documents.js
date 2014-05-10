var DOCUMENTS_SEARCH_TABLE = null;

//Poll every 5 seconds.
var JOB_DATA_POLL_INTERVAL = 5000;

jQuery(function($) {

  function runDocumentsControllerJS() {
    //enable tooltip
    $('.job-label').popover({html : true, trigger : 'hover'});

    //disables warnings, TODO to fix
    $.fn.dataTableExt.sErrMode = "throw";

    //intializeLiveMetaforms();

    //dataTables
    $.extend( $.fn.dataTableExt.oStdClasses, {
      //Taking out for now - URI too long
      //"sSortAsc": "header headerSortDown",
      //"sSortDesc": "header headerSortUp",
      //"sSortable": "header",
      "sWrapper": "dataTables_wrapper form-inline"
    });

    $.initDocumentDatatable = function ($, data_source) {
      if(data_source == undefined) {
        data_source = $('#documents').data('source');
      }

      //dataTables
      DOCUMENTS_SEARCH_TABLE = $('#documents').dataTable({
        "sPaginationType"  : "bootstrap",
        "bJQueryUI"      : true,
        "bProcessing"    : true,
        "bServerSide"    : true,
        "bSort"        : false,
        //Helps with long URIs
        //"fnServerParams": "",
        "sServerMethod"    : "POST",
        //Taking out search
        //"sDom": "<'row'<'span6'l><'span6'f>r>t<'row'<'span6'i><'span6'p>>",
        "sDom": "<'row'<'span6'l><'span6'f>r>t<'row'<'span6'i><'span6'p>>",
        "sAjaxSource"    : data_source
      });

      //Do a default search if the data attr is set (probably originally from
      // an HTML param)
      var default_search = $('#documents').data('default-search');
      if((default_search != undefined) && (default_search != "")) {
        DOCUMENTS_SEARCH_TABLE.fnFilter(default_search);
      }

      //only search on enter keypress 
      $('.dataTables_filter input')
          .unbind('keypress keyup')
          .bind('keypress keyup', function(e){
              if (e.keyCode != 13) return;
              DOCUMENTS_SEARCH_TABLE.fnFilter($(this).val());
          }
        );
    };
//----------------------------------------------------------------------
// Metadata editor code
//Add delete row button event
function delRow() {
  $(this).closest('tr').remove().off();
}

//Add add row button event
function addRow() {
  var md_row = $('#metadata_table').last('tr');
  var rowNew = '<tr> <td></td> <td></td> <td><button class="del_btn">Delete</button> </tr>'
  $(md_row).append(rowNew);
  $(md_row).find('tr').last().find('td').dblclick(inputForm); //adds input handler to new row
}

//Add input form when cell is double clicked
function inputForm() {
  if ( $(this).is('#del_btn_cell') )  //if ( $(this).children().is('.del_btn') )
    return;  //Prevents del button from becoming an input form
  
  var orignalText = $(this).text();
  $(this).html("<input type='text' value='" + orignalText + "' />");
  $(this).children().first().focus();

  $(this).children().first().keypress(function (e) {
    if (e.which == 13) {
      var newContent = $(this).val();
      $(this).parent().text(newContent);
    }
  });
  $(this).children().first().blur(function(){
    $(this).parent().text(orignalText);
  });
  
}

//Save new data and perform cleanup
function saveData() {
  var md_table = $('#metadata_table');
  endEdit(); //Cleanup
  var doc_url = window.location.pathname + '/doc_md_edit'     //Creat
  var jmd_table = md_table.tableToJSON({ headings: [0,1] });  //Convert table to json
  var pmd_table = {"md_table": jmd_table};  //Add key for table (for controller)
  
  $.ajax({
    url: doc_url,
    type: 'POST',
    dataType: "JSON",
    data: pmd_table,
  });
}

//Cancel button event and cleanup
function endEdit() {
  var md_table = $('#metadata_table');
  $('.add_btn').remove().off();
  $('.save_btn').remove().off();
  $('.del_btn').closest('td').remove().off();
  $('.cancel_btn').remove().off();
  $('.edit_md_btn').show();
  $(md_table).find('td').off(); //removes input form events on MD table?
}

//Metadata Editor
function md_editorSetup() {
  var md_table = $('#metadata_table');

  //Button setup
  var delButton = $('<td id="del_btn_cell"> <button id="delete_btn" class="del_btn">Delete</button> </td>');
  var addButton = $('<button class="add_btn">Add</button>');
  var saveButton = $('<button class="save_btn">Save</button>');
  var cancelButton = $('<button class="cancel_btn">Cancel</button>');
  
  $(md_table).find('tr').append(delButton);
  $('.edit_md_btn').before(addButton).before(saveButton).before(cancelButton).hide();

  //Click events
  $(md_table).on('click', '.del_btn', delRow);  //Delete row
  $('.add_btn').on('click', addRow);            //Add row
  $(md_table).find('td').dblclick(inputForm);   //Edit cell
  $('.save_btn').on('click', saveData);         //Save data
  $('.cancel_btn').on('click', endEdit);        //Cancel
}
//----------------------------------------------------------------------

  function show_notesJS() {
    var hide_notes = $('<a id="hide_notes_link">Hide Notes</a>');
    $('#show_notes_link').before(hide_notes).hide();
    $("#hide_notes_link").on('click', hide_notesJS);
    $("#notes").show();
  }
  
  function hide_notesJS() {
    $('#hide_notes_link').remove();
    $('#show_notes_link').show();
    $("#notes").hide();
  }
//----------------------------------------------------------------------

  //TODO: for later.
  function intializeLiveMetaforms() {
    var urlSource = $();
    $.ajax(urlSource, {
      //data: { data : "div.uploads" },
      cache: false,
      beforeSend: function(result) {
        //NTD
      },
      success: function(result) {
        
      },
      error: function(result) {
        //NTD
      },
      //timeout: NTD
    });
  }

    $(document).ready(function () {
      $.initDocumentDatatable($);
      $('.edit_md_btn').on('click', md_editorSetup); //Add editing event/handler
      $("#notes").hide();
      $("#show_notes_link").on('click', show_notesJS);
    });
  } //end runDocumentsControllerJS

  if(CONTROLLER_NAME == "documents") {
    runDocumentsControllerJS();
  } 
});
