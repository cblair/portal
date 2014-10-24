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

    //dataTables initialization.
    $.extend( $.fn.dataTableExt.oStdClasses, {
      //Taking out for now - URI too long
      //"sSortAsc": "header headerSortDown",
      //"sSortDesc": "header headerSortUp",
      //"sSortable": "header",
      "sWrapper": "dataTables_wrapper form-inline"
    });
/*
    //datatables - add first and last buttons
    $.extend( $.fn.dataTableExt.oPagination, {
    "bootstrap": {
        "fnInit": function( oSettings, nPaging, fnDraw ) {
            var oLang = oSettings.oLanguage.oPaginate;
            var fnClickHandler = function ( e ) {
                e.preventDefault();
                if ( oSettings.oApi._fnPageChange(oSettings, e.data.action) ) {
                    fnDraw( oSettings );
                }
            };
 
            $(nPaging).addClass('pagination pagination-right').append(
                '<ul>' +
                    '<li class="prev disabled"><a href="#">&larr; ' + oLang.sFirst + '</a></li>' +
                    '<li class="prev disabled"><a href="#">&larr; '+oLang.sPrevious+'</a></li>'+
                    '<li class="next disabled"><a href="#">' + oLang.sNext + ' &rarr; </a></li>' +
                    '<li class="next disabled"><a href="#">' + oLang.sLast + ' &rarr; </a></li>' +
                '</ul>'
            );
            var els = $('a', nPaging);
            $(els[0]).bind('click.DT', { action: "first" }, fnClickHandler);
            $(els[1]).bind( 'click.DT', { action: "previous" }, fnClickHandler );
            $(els[2]).bind('click.DT', { action: "next" }, fnClickHandler);
            $(els[3]).bind('click.DT', { action: "last" }, fnClickHandler);
        },
 
        "fnUpdate": function ( oSettings, fnDraw ) {
            var iListLength = 5;
            var oPaging = oSettings.oInstance.fnPagingInfo();
            var an = oSettings.aanFeatures.p;
            var i, j, sClass, iStart, iEnd, iHalf=Math.floor(iListLength/2);
 
            if ( oPaging.iTotalPages < iListLength) {
                iStart = 1;
                iEnd = oPaging.iTotalPages;
            }
            else if ( oPaging.iPage <= iHalf ) {
                iStart = 1;
                iEnd = iListLength;
            } else if ( oPaging.iPage >= (oPaging.iTotalPages-iHalf) ) {
                iStart = oPaging.iTotalPages - iListLength + 1;
                iEnd = oPaging.iTotalPages;
            } else {
                iStart = oPaging.iPage - iHalf + 1;
                iEnd = iStart + iListLength - 1;
            }
 
            for ( i=0, iLen=an.length ; i<iLen ; i++ ) {
                // Remove the middle elements
                $('li:gt(1)', an[i]).filter(':not(.next)').remove();
 
                // Add the new list items and their event handlers
                for ( j=iStart ; j<=iEnd ; j++ ) {
      sClass = (j==oPaging.iPage+1) ? 'class="active"' : '';
                    $('<li '+sClass+'><a href="#">'+j+'</a></li>')
                        .insertBefore( $('li.next:first', an[i])[0] )
                        .bind('click', function (e) {
                            e.preventDefault();
                            oSettings._iDisplayStart = (parseInt($('a', this).text(),10)-1) * oPaging.iLength;
                            fnDraw( oSettings );
                        } );
                }
 
                // Add / remove disabled classes from the static elements
                if ( oPaging.iPage === 0 ) {
                    $('li.prev', an[i]).addClass('disabled');
                } else {
                    $('li.prev', an[i]).removeClass('disabled');
                }
 
                if ( oPaging.iPage === oPaging.iTotalPages-1 || oPaging.iTotalPages === 0 ) {
                    $('li.next', an[i]).addClass('disabled');
                } else {
                    $('li.next', an[i]).removeClass('disabled');
                }
            }
        }
      }
    } ); //end datatables - add first and last buttons
*/

    $.initDocumentDatatable = function ($, data_source) {
      if(data_source == undefined) {
        data_source = $('#documents').data('source');
      }
/*
      //dataTables
      DOCUMENTS_SEARCH_TABLE = $('#documents').dataTable({
        "sPaginationType"  : "full_numbers", //"sPaginationType"  : "bootstrap",
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
*/
    }; //end initDocumentDatatable

//----------------------------------------------------------------------

//Cancel button event and cleanup
function endEdit() {
  location.reload(); //Refresh page so changes can take effect
}

//Add input form when cell is double clicked
function inputForm2() {
  var orignalText = $(this).text();
  $(this).html("<input type='text' class='edit_area' value='" + orignalText + "' />");
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

//Adds a new blank row, adds "add row" button event
function addRow() {
  var last_row = $('#metadata_table').find('tr').last();
  var rowNew = '<tr> <td class="editable"></td> <td class="editable"></td> <td> <button id="delete_btn" class="del_btn">Delete</button> </td>'
  $(last_row).after(rowNew);
  $(last_row).next().find('.editable').dblclick(inputForm2);
}

//Deletes row from table
function delRow() {
  $(this).closest('tr').remove().off();
}

//Save new data and perform cleanup
function saveData() {
  var md_table = $('#metadata_table');
  endEdit(); //Cleanup
  var doc_url = window.location.pathname + '/doc_md_edit'     //Create
  //var jmd_table = md_table.tableToJSON({ headings: [0,1] });  //Convert table to json OLD
  var jmd_table = md_table.tableToJSON();  //Convert table to json
  var pmd_table = {"md_table": jmd_table};  //Add key for table (for controller)
  
  $.ajax({
    url: doc_url,
    type: 'POST',
    dataType: "JSON",
    data: pmd_table,
  });
}

function md_editorSetup2() {
  var md_table = $('#metadata_table');
  
  //Button setup
  $('.edit_md_btn').hide();
  $('.sort_md_btn').hide();
  $('.edit_menu').show();
  var delButton = $('<td> <button id="delete_btn" class="del_btn">Delete</button> </td>');
  $(md_table).find('.md_row').append(delButton);
  
  //Click events
  $(md_table).on('click', '.del_btn', delRow);  //Delete row
  $('#add_btn').on('click', addRow);            //Add row
  $(md_table).find('.editable').dblclick(inputForm2); //Makes cell editable
  $('#save_btn').on('click', saveData);         //Save data
  $('#cancel_btn').on('click', endEdit);        //Cancel changes
  
}
//----------------------------------------------------------------------
// Return a helper with preserved width of cells when sorting
var fixHelper = function(e, ui) {
  ui.children().each(function() {
    $(this).width($(this).width());
  });
  return ui;
};

//----------------------------------------------------------------------
function sort_editor() {
  //Button setup
  $('.edit_md_btn').hide();
  $('.sort_md_btn').hide();
  $('.sort_menu').show();
  
  $("#metadata_table tbody").sortable({
    helper: fixHelper }).disableSelection();  //Make table D&D sortable
    
  $('#save_sort_btn').on('click', saveData);  //Save sorted data
  $('#cancel_sort_btn').on('click', endEdit); //Cancel sorting changes
}

//----------------------------------------------------------------------
  function show_notesJS() {
    var hide_notes = $('<a id="hide_notes_link" class="btn btn-small">Hide Notes</a>');
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
      $('.edit_menu').hide();
      $('.sort_menu').hide();
      //Enter editing "mode", add editing event/handler
      $('.edit_md_btn').on('click', md_editorSetup2);
      $('.sort_md_btn').on('click', sort_editor);
      
      $("#notes").hide();
      $("#show_notes_link").on('click', show_notesJS);
      
      //enable tooltip
      $('#doc_info').popover({html : true, placement : 'bottom', trigger : 'click'});
    });
  } //end runDocumentsControllerJS

  if(CONTROLLER_NAME == "documents") {
    runDocumentsControllerJS();
  } 
});
