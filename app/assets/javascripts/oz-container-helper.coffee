#function to remove nonbootstrap container class
$(document).ready ->
  if $('.js-remove-their-container').length > 0
    $('.their-container').removeClass 'their-container'
  return

$(document).ready ->
  map = $('.oz-map-container')
  map_width = map.width()
  sidebar_height = $('.walking-guide__sidebar').height()
  if $(document).width() < 992
    map.css 'height', "#{map_width}px"
  else
    map.css 'height', "#{sidebar_height}px"

jQuery.initializer '.js-remove-if-not-carousel', ->
  class_list = $('.js-remove-if-not-carousel')
  caro = $('.modal-body')
  if caro
    class_list.each ->
    cont = $(this).contents()
    $(this).replaceWith cont

jQuery.initializer '.modal-body', ->
  div = $('.js-remove-if-modal')
  div.removeClass 'container'
  div.focus()

change_map_size = ->
  map = $('#map-poland')
  if window.innerWidth < 356
    map.removeClass 'm340'
    map.addClass 'm240'
  else
    map.removeClass 'm240'
    map.addClass 'm340'

$(document).ready ->
  change_map_size()

$(window).resize ->
  change_map_size()