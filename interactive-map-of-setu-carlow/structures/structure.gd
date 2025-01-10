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
	var this_position: Vector3 = convert_longitude_latitude_to_coordinate(longitude, latitude)
	var global_base_position: Vector3 = convert_longitude_latitude_to_coordinate(Globals.base_longitude, Globals.base_latitude)
	
	global_position = (this_position - global_base_position) * 5

# Convert using Mercator projection
func convert_longitude_latitude_to_coordinate(longitude: float, latitude: float) -> Vector3:
	const EARTH_RADIUS = 63781.370

	# Convert latitude and longitude to radians
	var longitude_radians: float = deg_to_rad(longitude)
	var latitude_radians: float = deg_to_rad(latitude)

	# Calculate coordinates using the Mercator projection
	var x_coordinate: float = longitude_radians * EARTH_RADIUS
	var z_coordinate: float = log(tan(PI / 4.0 + latitude_radians / 2.0)) * EARTH_RADIUS

	return Vector3(x_coordinate, 0, z_coordinate)
