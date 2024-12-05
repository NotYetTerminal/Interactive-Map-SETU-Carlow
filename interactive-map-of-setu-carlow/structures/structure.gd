extends StaticBody3D
class_name Structure

var id: String

var longitude: float
var latitude: float

@warning_ignore("unused_parameter")
func save_details(id_in: String, details: Dictionary) -> void:
	pass

@warning_ignore("unused_parameter")
func update_details(details: Dictionary) -> void:
	pass

@warning_ignore("unused_parameter")
func update_waypoints_time(new_time: int) -> void:
	pass

# Set the position of the structue based on the GPS coordinates
func set_structure_global_position() -> void:
	global_position = Vector3(longitude - Globals.base_longitude, 0, latitude - Globals.base_latitude) * 10000
