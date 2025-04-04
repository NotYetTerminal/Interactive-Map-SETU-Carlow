extends Structure
class_name Room

var description: String
var lectures: String

var floor_number: int

var waypoints_updated_time: int

@onready var waypoints_node: Node3D = $Waypoints
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D


# Save details from map_data
func save_details(id_in: String, details: Dictionary) -> Array[String]:
	id = id_in
	
	# When the structure is created no data is passed to it
	if details.is_empty():
		return []
	
	var changed_fields: Array[String] = [
		"longitude" if longitude != details["longitude"] else "",
		"latitude" if latitude != details["latitude"] else "",
		"name" if structure_name != details["name"] else "",
		"description" if description != details["description"] else "",
		"lecturers" if lectures != details["lecturers"] else "",
		"floor_number" if floor_number != details["floor_number"] else "",
		"waypoints_updated_time" if waypoints_updated_time != details["waypoints_updated_time"] else ""
	]
	
	longitude = details["longitude"]
	latitude = details["latitude"]
	
	structure_name = details["name"]
	description = details["description"]
	lectures = details["lecturers"]
	
	floor_number = details["floor_number"]
	
	waypoints_updated_time = details["waypoints_updated_time"]
	
	set_structure_global_position()
	return changed_fields

# Update the details when editing
func update_details(details: Dictionary) -> void:
	var fields: Array[String] = save_details(id, details)
	var building: Building = get_parent_structure()
	var base_map: BaseMap = building.get_parent_structure()
	
	var room_dictionary: Dictionary = Globals.offline_data[base_map.id]['Buildings'][building.id]
	if not room_dictionary.has('Rooms'):
		room_dictionary['Rooms'] = {}
	
	room_dictionary = room_dictionary['Rooms']
	if room_dictionary.has(id):
		var room_data: Dictionary = room_dictionary[id]
		if not room_data.has('Waypoints'):
			room_data['Waypoints'] = {}
		details['Waypoints'] = room_data['Waypoints']
	
	room_dictionary[id] = details
	await Globals.save_data(id, fields, current_firestore_path(), details)
	
	building.update_rooms_time(int(Time.get_unix_time_from_system()))

# Used by children to update time
func update_waypoints_time(new_time: int) -> void:
	waypoints_updated_time = new_time
	var building: Building = get_parent_structure()
	var base_map: BaseMap = building.get_parent_structure()
	
	Globals.offline_data[base_map.id]['Buildings'][building.id]['Rooms'][id]['waypoints_updated_time'] = waypoints_updated_time
	var structure_data: Dictionary = Globals.offline_data[base_map.id]['Buildings'][building.id]['Rooms'][id]
	await Globals.save_data(id, ['waypoints_updated_time'], current_firestore_path(), structure_data)
	
	building.update_rooms_time(waypoints_updated_time)

# Set global position, and update children
func set_structure_global_position() -> void:
	super.set_structure_global_position()
	for waypoint: Waypoint in waypoints_node.get_children():
		waypoint.set_structure_global_position()

# Delete the structure and data related to it
func delete_itself() -> void:
	# Delete all Waypoints in the Rooms
	for waypoint: Waypoint in waypoints_node.get_children():
		await waypoint.delete_itself()
	
	var building: Building = get_parent_structure()
	var base_map: BaseMap = building.get_parent_structure()
	var rooms_dictionary: Dictionary = Globals.offline_data[base_map.id]['Buildings'][building.id]['Rooms']
	var _erased: bool = rooms_dictionary.erase(id)
	building.update_rooms_time(int(Time.get_unix_time_from_system()))
	
	await Globals.delete_structure(base_map.id + '/Buildings/' + building.id + '/Rooms', id)
	self.queue_free()

# Used by Waypoint children to get data
func get_offline_data_waypoints() -> Dictionary:
	var building: Building = get_parent_structure()
	var base_map: BaseMap = building.get_parent_structure()
	var structure_dictionary: Dictionary = Globals.offline_data[base_map.id]['Buildings'][building.id]['Rooms'][id]
	if not structure_dictionary.has('Waypoints'):
		structure_dictionary['Waypoints'] = {}
	return structure_dictionary['Waypoints']

# Used by Waypoint children to get path of parent
func get_firestore_path() -> String:
	return current_firestore_path() + "/" + id


func get_parent_structure() -> Building:
	return get_parent().get_parent()


func current_firestore_path() -> String:
	return get_parent_structure().get_firestore_path() + "/Rooms"

# Used by Pathfinder to get Waypoint in the Room
func get_closest_waypoint() -> Waypoint:
	var closest_distance: float = 10000
	var closest_waypoint: Waypoint
	for waypoint: Waypoint in waypoints_node.get_children():
		var distance: float = global_position.distance_to(waypoint.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_waypoint = waypoint
	return closest_waypoint


func update_visibility() -> void:
	mesh_instance_3d.visible = floor_number == Globals.current_floor
	collision_shape_3d.disabled = floor_number != Globals.current_floor
	for waypoint: Waypoint in waypoints_node.get_children():
		waypoint.update_visibility()


func set_icon_scale(new_scale: float) -> void:
	mesh_instance_3d.scale = Vector3(new_scale, new_scale, new_scale)
	collision_shape_3d.scale = Vector3(new_scale, new_scale, new_scale)
