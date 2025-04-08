extends Structure
class_name BaseMap

@onready var waypoints_node: Node3D = $Waypoints
@onready var buildings_node: Node3D = $Buildings
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

var waypoints_updated_time: int
var buildings_updated_time: int


func _ready() -> void:
	Globals.base_map = self
	structure_name = "Base Map"


# Save details from map_data
func save_details(id_in: String, details: Dictionary) -> Array[String]:
	id = id_in
	
	var changed_fields: Array[String] = [
		"longitude" if longitude != details["longitude"] else "",
		"latitude" if latitude != details["latitude"] else "",
		"waypoints_updated_time" if waypoints_updated_time != details["waypoints_updated_time"] else "",
		"buildings_updated_time" if buildings_updated_time != details["buildings_updated_time"] else ""
	]
	
	longitude = details["longitude"]
	latitude = details["latitude"]
	
	Globals.base_longitude = longitude
	Globals.base_latitude = latitude
	
	waypoints_updated_time = details["waypoints_updated_time"]
	buildings_updated_time = details["buildings_updated_time"]
	
	set_structure_global_position()
	return changed_fields

# Update the details when editing
func update_details(details: Dictionary) -> void:
	var fields: Array[String] = save_details(id, details)
	var base_map_data: Dictionary = Globals.offline_data[id]
	details['Buildings'] = base_map_data['Buildings']
	details['Waypoints'] = base_map_data['Waypoints']
	
	Globals.offline_data[id] = details
	await Globals.save_data(id, fields, current_firestore_path(), details)
	
	saved = true

# Used by children to update time
func update_buildings_time(new_time: int) -> void:
	buildings_updated_time = new_time
	Globals.offline_data[id]['buildings_updated_time'] = buildings_updated_time
	var structure_data: Dictionary = Globals.offline_data[id]
	await Globals.save_data(id, ['buildings_updated_time'], current_firestore_path(), structure_data)


func update_waypoints_time(new_time: int) -> void:
	waypoints_updated_time = new_time
	Globals.offline_data[id]['waypoints_updated_time'] = waypoints_updated_time
	var structure_data: Dictionary = Globals.offline_data[id]
	await Globals.save_data(id, ['waypoints_updated_time'], current_firestore_path(), structure_data)

# Used by Waypoint children to get data
func get_offline_data_waypoints() -> Dictionary:
	var structure_dictionary: Dictionary = Globals.offline_data[id]
	if not structure_dictionary.has('Waypoints'):
		structure_dictionary['Waypoints'] = {}
	return structure_dictionary['Waypoints']

# Used by Waypoint children to get path of parent
func get_firestore_path() -> String:
	return current_firestore_path() + "/" + id


func current_firestore_path() -> String:
	return "Base_Map"

# Set global position, and update children
func set_structure_global_position() -> void:
	super.set_structure_global_position()
	for waypoint: Waypoint in waypoints_node.get_children():
		waypoint.set_structure_global_position()
	for building: Building in buildings_node.get_children():
		building.set_structure_global_position()


func enable_admin() -> void:
	mesh_instance_3d.visible = Globals.edit_mode
	collision_shape_3d.disabled = not Globals.edit_mode


func update_visibility() -> void:
	for waypoint: Waypoint in waypoints_node.get_children():
		waypoint.update_visibility()
	for building: Building in buildings_node.get_children():
		building.update_visibility()


func set_icon_scale(new_scale: float) -> void:
	mesh_instance_3d.scale = Vector3(new_scale, new_scale, new_scale)
	collision_shape_3d.scale = Vector3(new_scale, new_scale, new_scale)
