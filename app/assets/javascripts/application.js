// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require jquery/jquery-2.1.1.js
//= require bootstrap-sprockets
//= require jquery.inputmask
//= require metisMenu/jquery.metisMenu.js
//= require pace/pace.min.js
//= require slimscroll/jquery.slimscroll.min.js
//= require dataTables/jquery.dataTables.js
//= require dataTables/dataTables.bootstrap.js
//= require dataTables/dataTables.responsive.js
//= require dataTables/dataTables.tableTools.min.js
//= require jquery_nested_form
//= require toastr
// require inspinia.js
//= require chartjs/Chart.min.js
//= require bootstrap-datepicker
//=  require_tree .

$(document).ready(function() {

  //Ransak das telas index
  $('form').on('click', '.remove_fields', function(event) {
    $(this).closest('.field').remove();
    return event.preventDefault();
  });
  return $('form').on('click', '.add_fields', function(event) {
    var regexp, time;
    time = new Date().getTime();
    regexp = new RegExp($(this).data('id'), 'g');
    $(this).before($(this).data('fields').replace(regexp, time));
    return event.preventDefault();
  });

  // $('.Tabela').dataTable({
  //   "dom": 'T<"clear">lfrtip',
  //   "aoColumnDefs": [
  //         { 'bSortable': false, 'aTargets': [ 0,1,2 ] }
  //      ],
  //   "tableTools": {
  //       "sSwfPath": "../assets/dataTables/swf/copy_csv_xls_pdf.swf"
  //   }
  // });
  
  // $(".datepicker").inputmask("99/99/9999");
  // $(".datepicker").datepicker({ dateFormat: 'dd/mm/yyyy', autoSize:true });  
});
