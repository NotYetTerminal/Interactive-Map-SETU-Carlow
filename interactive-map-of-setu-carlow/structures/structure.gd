extends StaticBody3D
class_name Structure

var id: String

var longitude: float
var latitude: float
var structure_name: String


func save_details(_id_in: String, _details: Dictionary) -> Array[String]:
	return []


func update_details(_details: Dictionary) -> void:
	pass


func update_waypoints_time(_new_time: int) -> void:
	pass

# Delete the structure and data related to it
func delete_itself() -> void:
	pass

# Used by Waypoint children to get data
func get_offline_data_waypoints() -> Dictionary:
	return {}


func get_parent_structure() -> Structure:
	return null

# Used by Waypoint children to get path of parent
func get_firestore_path() -> String:
	return ""

# Used to update the visibility of Structures
func update_visibility() -> void:
	pass

# Set the position of the structue based on the GPS coordinates
func set_structure_global_position() -> void:
	var this_position: Vector3 = equirectangular_conversion(longitude, latitude)
	var global_base_position: Vector3 = equirectangular_conversion(Globals.base_longitude, Globals.base_latitude)
	
	global_position = (this_position - global_base_position) / 10

# Convert using Equirectangular projection
func equirectangular_conversion(lon: float, lat: float) -> Vector3:
	# Convert latitude and longitude to radians
	var longitude_radians: float = deg_to_rad(lon)
	var latitude_radians: float = deg_to_rad(lat)
	
	# Calculate coordinates using the Equirectangular projection
	var x_coordinate: float = longitude_radians * cos(deg_to_rad(Globals.base_latitude))
	var z_coordinate: float = latitude_radians
	
	return Vector3(x_coordinate, 0, z_coordinate) * Globals.EARTH_RADIUS
