$(document).ready(function() {
  // keep the dropdown open when clicking inside the element
  $('.exportButtonWrapper .dropdown-menu').click(function(e) {
      e.stopPropagation();
  });

  // enable the submit button when at least one datastream checkbox is selected
  $('.exportButtonWrapper .dropdown-menu input.datastream').on('change', function(e) {
    setSubmitButtonState();
  });

  function setSubmitButtonState() {
    var $exportButton = $('.exportButtonWrapper .dropdown-menu input[data-behavior=batch-create]');

    $exportButton.attr('disabled', true);

    $.each($('.exportButtonWrapper .dropdown-menu input.datastream'), function(index, element) {
      if ( $(element).is(':checked') ) {
        $exportButton.attr('disabled', false);
      }
    });
  };


  setSubmitButtonState();
});
