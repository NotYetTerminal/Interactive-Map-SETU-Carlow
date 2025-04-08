extends Node3D
class_name Structure

var id: String

var longitude: float
var latitude: float
var structure_name: String

var mouse_editing: bool = false
var just_moved: bool = false
var saved: bool = false


func _process(_delta: float) -> void:
	if mouse_editing:
		var mouse_position: Vector2 = get_viewport().get_mouse_position()
		var camera: Camera3D = get_viewport().get_camera_3d()
		var origin: Vector3 = camera.project_ray_origin(mouse_position)
		var direction: Vector3 = camera.project_ray_normal(mouse_position)

		var distance: float = -origin.y/direction.y
		var xz_position: Vector3 = origin + direction * distance
		
		global_position = Vector3(xz_position.x, 0, xz_position.z)
		set_structure_lon_lat()


func _unhandled_input(event: InputEvent) -> void:
	if mouse_editing and event is InputEventMouseButton:
		var mouse_input_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_input_event.button_index == MOUSE_BUTTON_LEFT:
			mouse_editing = false
			just_moved = true
			if self is Waypoint:
				(self as Waypoint).update_links(true)


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

# Set the position of the structue based on the X Z coordinates
func set_structure_lon_lat() -> void:
	var this_coordinates: Vector2 = inverse_equirectangular_conversion(global_position.x, global_position.z)
	
	this_coordinates = (this_coordinates * 10) + Vector2(Globals.base_longitude, Globals.base_latitude)
	longitude = this_coordinates.x
	latitude = this_coordinates.y

# Convert using Equirectangular projection
func equirectangular_conversion(lon: float, lat: float) -> Vector3:
	# Convert latitude and longitude to radians
	var longitude_radians: float = deg_to_rad(lon)
	var latitude_radians: float = deg_to_rad(lat)
	
	# Calculate coordinates using the Equirectangular projection
	var x_coordinate: float = longitude_radians * cos(deg_to_rad(Globals.base_latitude))
	var z_coordinate: float = latitude_radians
	
	return Vector3(x_coordinate, 0, z_coordinate) * Globals.EARTH_RADIUS

# Convert using inverse Equirectangular projection
func inverse_equirectangular_conversion(x_coordinate: float, z_coordinate: float) -> Vector2:
	# Convert the coordinates back to radians
	var longitude_radians: float = x_coordinate / Globals.EARTH_RADIUS / cos(deg_to_rad(Globals.base_latitude))
	var latitude_radians: float = z_coordinate / Globals.EARTH_RADIUS

	# Convert radians back to degrees
	var lon: float = rad_to_deg(longitude_radians)
	var lat: float = rad_to_deg(latitude_radians)

	return Vector2(lon, lat)
