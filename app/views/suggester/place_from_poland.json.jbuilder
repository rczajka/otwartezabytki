json.array!(@places) do |json, place|
  json.(place, :id, :name, :location_names, :latitude, :longitude)
end
