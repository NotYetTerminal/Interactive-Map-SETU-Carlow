extends StaticBody3D
class_name Structure

var id: String

var longitude: float
var latitude: float

@warning_ignore("unused_parameter")
func save_details(id_in: String, details: Dictionary) -> Array[String]:
	return []

@warning_ignore("unused_parameter")
func update_details(details: Dictionary) -> void:
	pass

@warning_ignore("unused_parameter")
func update_waypoints_time(new_time: int) -> void:
	pass

# Set the position of the structue based on the GPS coordinates
func set_structure_global_position() -> void:
	var this_position: Vector3 = equirectangular_conversion(longitude, latitude)
	@warning_ignore("unsafe_property_access")
	@warning_ignore("unsafe_call_argument")
	var global_base_position: Vector3 = equirectangular_conversion(Globals.base_longitude, Globals.base_latitude)
	
	global_position = (this_position - global_base_position) / 10

# Convert using Mercator projection
func mercator_conversion(lon: float, lat: float) -> Vector3:
	# Convert latitude and longitude to radians
	var longitude_radians: float = deg_to_rad(lon)
	var latitude_radians: float = deg_to_rad(lat)

	# Calculate coordinates using the Mercator projection
	var x_coordinate: float = longitude_radians
	var z_coordinate: float = log(tan(PI / 4.0 + latitude_radians / 2.0))

	@warning_ignore("unsafe_property_access")
	return Vector3(x_coordinate, 0, z_coordinate) * Globals.EARTH_RADIUS

# Convert using Equirectangular projection
func equirectangular_conversion(lon: float, lat: float) -> Vector3:
	# Convert latitude and longitude to radians
	var longitude_radians: float = deg_to_rad(lon)
	var latitude_radians: float = deg_to_rad(lat)
	
	# Calculate coordinates using the Equirectangular projection
	@warning_ignore("unsafe_property_access")
	@warning_ignore("unsafe_call_argument")
	var x_coordinate: float = longitude_radians * cos(deg_to_rad(Globals.base_latitude))
	var z_coordinate: float = latitude_radians

	@warning_ignore("unsafe_property_access")
	return Vector3(x_coordinate, 0, z_coordinate) * Globals.EARTH_RADIUS
