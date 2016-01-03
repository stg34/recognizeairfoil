json.array!(@airfoils) do |airfoil|
  json.extract! airfoil, :id, :raw, :coordinates, :top, :bottom, :name, :comment, :fixes
  json.url airfoil_url(airfoil, format: :json)
end
