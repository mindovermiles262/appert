$(document).ready(function() {
  // Removes Sample fields from Projects Form
  $('form').on('click', '.destroy_fields', function() {
    $(this).prev('input[type=hidden]').val('1')
    $(this).closest('.fieldset').hide()
    event.preventDefault()
  })

  // Adds Test fields to Samples form
  $('form').on('click', '.add_fields', function() {
    time = new Date().getTime()
    regex = new RegExp($(this).data('id'), 'g')
    $(this).before($(this).data('fields').replace(regex, time))
    event.preventDefault()
  })

  $('table').on('click', '.destroy_row', function() {
    console.log("click");
    $(this).prev('input[type=hidden]').val('1')
    $(this).closest('tr').hide()
    event.preventDefault()
  })
});