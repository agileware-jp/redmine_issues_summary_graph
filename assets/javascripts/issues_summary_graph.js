$(function(){
  $("#include_subproject").on("click", function(){
    $.ajax({
      type: "GET",
      url: $(this).data("url"),
      dataType: "json",
      data: {
        include_subproject: $(this).prop("checked")
      },
      success: function(data){
        $("#tracker_ids").html(data.tracker_options);
        $("#version_ids").html(data.version_options);
        $("#issue_category_ids").html(data.issue_category_options);
      }
    });
  });
});
