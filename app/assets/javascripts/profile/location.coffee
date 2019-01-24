#= require vendor/gmaps

window.map = undefined

window.geocode_location = (callback) ->
  return unless callback?
  if $('#relic_polish_relic').is(':checked')
    if $('#relic_street').is(':visible')
      voivodeship = $('#relic_voivodeship_id option:selected').text().trim()
      district = $('#relic_district_id option:selected').text().trim()
      commune = $('#relic_commune_id option:selected').text().trim()
      city = $('#relic_place_id option:selected').text().trim()
      street = $('#relic_street').val().trim()
      query = {voivodeship, district, commune, city, street}
    else
      place_id = $('#relic_place_id').val()
      query = {place_id} if place_id

    jQuery.get geocoder_search_path, query, (result) ->
      if result.length > 0
        callback(result[0].latitude.round(7), result[0].longitude.round(7))
    , 'json' if query
  else
    country_code = $('#relic_country_code').val()
    province = $('#relic_fprovince').val()
    place = $('#relic_fplace').val().trim()
    street = $('#relic_street').val().trim()

    jQuery.get geocoder_search_path, {country_code, province, city, street}, (result) ->
      if result.length > 0
        callback(result[0].latitude.round(7), result[0].longitude.round(7))
    , 'json'

$.fn.specialize

  '#map_canvas':

    map: -> map

    zoom_at: (lat, lng, zoom = 17) ->
      if window.map
        window.map.setCenter(lat, lng)
        window.map.map.setZoom(zoom)
      else
        window.map = new GMaps
          div: '#map_canvas'
          width: 340
          height: 340
          zoom: zoom
          lat: lat
          lng: lng
          mapTypeId: google.maps.MapTypeId.HYBRID

    auto_zoom: (zoom = 17) ->
      latitude = $('#relic_latitude').val().toNumber()
      longitude = $('#relic_longitude').val().toNumber()
      this.zoom_at(latitude, longitude, zoom)
      map.removeMarkers()
      this.circle_marker(latitude, longitude)

    circle_marker: (latitude, longitude) ->
      map.circle_lat = latitude
      map.circle_lng = longitude
      map.addMarker
        lat: latitude
        lng: longitude
        icon: new google.maps.MarkerImage(small_marker_image_path, null, null, new google.maps.Point(8, 8))

    set_marker: (lat, lng) ->
      $('form.relic').addClass('geocoded')
      $('#relic_geocoded').val("t")
      map.removeMarkers()

      marker = map.addMarker
        lat: lat
        lng: lng
        draggable: true
        dragend: (e) ->
          new_lat = marker.getPosition().lat().round(7)
          new_lng = marker.getPosition().lng().round(7)
          $('#relic_latitude').val(new_lat)
          $('#relic_longitude').val(new_lng)
          $('#map_canvas').zoom_at(new_lat, new_lng)

        $('#relic_latitude').val(lat.round(7))
        $('#relic_longitude').val(lng.round(7))

      $('#map_canvas').zoom_at(lat, lng)

    blinking: ->
      clearTimeout(map.timer) if map && map.timer
      if map && $('#map_canvas').length
        unless $('form.relic').hasClass('geocoded')
          map.counter ||= 1
          map.counter += 1
          if map.counter % 2
            this.circle_marker(map.circle_lat, map.circle_lng) if map.markers.length == 0
          else
            map.removeMarkers()
        map.timer = setTimeout ->
          $('#map_canvas').blinking()
        , 1000

window.google_maps_loaded = ->
  window.is_google_maps_loaded = true
  window.loadGMaps() if not GMaps
  do window.google_maps_loaded_callback if window.google_maps_loaded_callback

window.google_maps_loaded_callback = null

window.load_google_maps = ->
  script = document.createElement("script")
  script.type = "text/javascript"
  script.src = "https://maps.googleapis.com/maps/api/js?key=#{window.google_maps_key}&sensor=false&callback=google_maps_loaded"
  document.body.appendChild(script)

window.ensuring_google_maps_loaded = (callback) ->
  if window.is_google_maps_loaded
    do callback
  else
    window.google_maps_loaded_callback = callback
    do window.load_google_maps

window.ensure_geolocation = ->
  if $('#relic_latitude').val()?.length > 0
    $('#map_canvas').auto_zoom()
  else
    $('#relic_latitude').val 52.4118436
    $('#relic_longitude').val 19.0984013
    $('#map_canvas').auto_zoom(6)
    try
      navigator.geolocation.getCurrentPosition (pos) ->
        $('#relic_latitude').val pos.coords.latitude
        $('#relic_longitude').val pos.coords.longitude
        $('#map_canvas').auto_zoom(17)

jQuery.initializer 'section.oz-edit.location', ->
  $('#relic_place_id').select2()
  $('#relic_place_id').change ->
    $('#relic_street').val("")

  $('#relic_polish_relic').change ->
    if $(this).is(':checked')
      $('.foreign-location').hide()
      $('.polish-location').show()
    else
      $('.polish-location').hide()
      $('.foreign-location').show()

  this.find(".toggle_street_input").click ->
    if $('.street_input').is(':visible')
      $('.street_input').hide()
      $('.street_input input').val("")
      $(this).text("Znam dokładny adres")
    else
      $('.street_input').show()
      $(this).text("Nie da się ustalić adresu")

    false

  window.ensuring_google_maps_loaded ->

    window.ensure_geolocation()

    $('#marker').draggable
      revert: true

    $('#map_canvas').droppable
      drop: (event, ui) ->

        x_offset = (ui.offset.left - $(this).offset().left + 39)
        y_offset = (ui.offset.top - $(this).offset().top + 55)

        lng = map.map.getBounds().getSouthWest().lng()
        lat = map.map.getBounds().getNorthEast().lat()
        width = map.map.getBounds().getNorthEast().lng() - map.map.getBounds().getSouthWest().lng()
        height = map.map.getBounds().getSouthWest().lat() - map.map.getBounds().getNorthEast().lat()
        marker_lat = lat + height * y_offset / $(this).height()
        marker_lng = lng + width * x_offset / $(this).width()
        $('#map_canvas').set_marker(marker_lat, marker_lng)

    $('#map_canvas').blinking()

    if $('form.relic').hasClass('geocoded')
      $('#map_canvas').set_marker($('#relic_latitude').val().toNumber(), $('#relic_longitude').val().toNumber())

    $('form.relic').on 'change',  '.foreign-location select, .foreign-location input, .street_input input, #relic_polish_relic', ->
      $('form.relic').addClass('wait')
      geocode_location (lat, lng) ->
        $('#map_canvas').set_marker(lat, lng)
        $form = $('form.relic')
        $form.removeClass('wait')
        $form.submit() if $form.hasClass('submit')

  countries_locations = jQuery.parseJSON($('#countries_location').html())
  $('#relic_country_code').select2()
  $('#relic_country_code').change ->
    location = countries_locations[$(this).val()]
    $('#map_canvas').zoom_at(location[0], location[1], 5)

  $('form.relic').on 'ajax:before', ->

    # Wait for lat/lng
    if $(this).hasClass('wait')
      $(this).addClass('submit')
      return false

    unless $(this).hasClass('geocoded')
      alert("Podaj dokładny adres lub przeciągnij znacznik na mapę.")
      return false

  $('.administrative-level select').on 'change', ->
    $('#relic_street').val('')
