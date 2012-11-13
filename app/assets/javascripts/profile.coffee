#= require sugar
#= require_self
#= require_tree ./profile

jQuery.initializer 'section.show.photos', ->
  $section = this
  if slider = $section.find('#slider_mini')[0]
    photos = $(slider).data('photos')
    $(slider).jcarousel
      size: photos.length
      itemLoadCallback:
        onBeforeAnimation: (carousel, state) ->
          for i in [carousel.first..carousel.last]
            continue if carousel.has(i)
            break if i > photos.length
            item = photos[i - 1]
            carousel.add(i, "<a href='#{Routes.relic_photo_path(item.relic_id, item.id)}' data-maxi='#{item.file.maxi.url}' data-author='#{item.author}'><img src='#{item.file.mini.url}' width='80' height='60' alt='Zdjęcie zrobione przez #{item.author}' /></a>")

    $(slider).on 'click', 'a[data-maxi]', ->
      $section.find('.main-photo span').html($(this).data('author'))
      $section.find('.main-photo img').attr('src', $(this).data('maxi'))
      $section.find('.main-photo').attr('href', $(this).attr('href'))
      false

jQuery.initializer 'section.show.photo', ->
  $section = this
  if slider = $section.find('#slider_midi')[0]
    photos = $(slider).data('photos')
    $(slider).jcarousel
      size: photos.length
      itemLoadCallback:
        onBeforeAnimation: (carousel, state) ->
          for i in [carousel.first..carousel.last]
            continue if carousel.has(i)
            break if i > photos.length
            item = photos[i - 1]
            carousel.add(i, "<a data-remote='true' href='#{Routes.relic_photo_path(item.relic_id, item.id)}' data-main='#{item.main}'><img src='#{item.file.midi.url}' alt='Zdjęcie zrobione przez #{item.author}' /></a>")

$('body').on "click", ".close_popover", ->
  $("##{$(this).data('popover-id')}").popover('hide')
  false

jQuery.initializer 'body.relics.show', ->
  this.on 'click', 'a[href^="/relics/0/"]', (e) ->
    alert('To tylko podgląd. Nie możesz nic edytować.')
    false

jQuery.initializer 'section.edit', ->
  this.find('form').each ->
    $form = $(this)

    $form.on 'change', 'input', ->
      $form.data('changed', true)

    $form.on 'click', 'a.cancel', ->
      if $form.data('changed') || $form.find('input.error').length
        return confirm('Na pewno? Stracisz wprowadzone zmiany w tej sekcji.')
      else
        return true

jQuery.initializer 'section.show.subrelics', ->
  $(".subrelics-tree li a").click ->
    $('body').scrollTop(0)

jQuery.initializer 'section.show', ->
  this.find('a.fancybox').fancybox()

jQuery ->
  $('body').on 'click', '.flash-info-permament span', ->
    $.cookie('flash_hidden', true)