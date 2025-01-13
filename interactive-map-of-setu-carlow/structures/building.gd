extends Structure
class_name Building

var structure_name: String
var description: String
var building_letter: String

@export var waypoints: Node
@export var rooms: Node

var waypoints_updated_time: int
var rooms_updated_time: int

# Contains textures for buildings { structure_name: String: texture_scene: PackedScene }
@export var map_textures_dictionary: Dictionary

# Save details from map_data
func save_details(id_in: String, details: Dictionary) -> Array[String]:
	@warning_ignore("unsafe_call_argument")
	var changed_fields: Array[String] = [
		"longitude" if longitude != details["longitude"]["doubleValue"] else "",
		"latitude" if latitude != details["latitude"]["doubleValue"] else "",
		"name" if structure_name != details["name"]["stringValue"] else "",
		"description" if description != details["description"]["stringValue"] else "",
		"building_letter" if building_letter != details["building_letter"]["stringValue"] else "",
		"waypoints_updated_time" if waypoints_updated_time != int(details["waypoints_updated_time"]["integerValue"]) else "",
		"rooms_updated_time" if rooms_updated_time != int(details["rooms_updated_time"]["integerValue"]) else ""
	]
	id = id_in
	
	longitude = details["longitude"]["doubleValue"]
	latitude = details["latitude"]["doubleValue"]
	
	structure_name = details["name"]["stringValue"]
	description = details["description"]["stringValue"]
	building_letter = details["building_letter"]["stringValue"]
	
	@warning_ignore("unsafe_call_argument")
	waypoints_updated_time = int(details["waypoints_updated_time"]["integerValue"])
	@warning_ignore("unsafe_call_argument")
	rooms_updated_time = int(details["rooms_updated_time"]["integerValue"])
	
	set_structure_global_position()
	
	add_map_texture()
	return changed_fields

# Update the details when editing
func update_details(details: Dictionary) -> void:
	var fields: Array[String] = save_details(id, details)
	var base_map: BaseMap = get_parent().get_parent()
	var building_data: Dictionary = Globals.offline_data[base_map.id]['Buildings'][id]
	
	details['Rooms'] = building_data['Rooms']
	details['Waypoints'] = building_data['Waypoints']
	Globals.offline_data[base_map.id]['Buildings'][id] = details
	base_map.update_buildings_time(int(Time.get_unix_time_from_system()))
	
	Globals.save_data(id, fields)

# Used by children to update time
func update_rooms_time(new_time: int) -> void:
	rooms_updated_time = new_time
	var base_map: BaseMap = get_parent().get_parent()
	Globals.offline_data[base_map.id]['Buildings'][id]['rooms_updated_time'] = {'integerValue': str(rooms_updated_time)}
	base_map.update_buildings_time(waypoints_updated_time)

func update_waypoints_time(new_time: int) -> void:
	waypoints_updated_time = new_time
	var base_map: BaseMap = get_parent().get_parent()
	Globals.offline_data[base_map.id]['Buildings'][id]['waypoints_updated_time'] = {'integerValue': str(waypoints_updated_time)}
	base_map.update_buildings_time(waypoints_updated_time)

# Set global position, and update children
func set_structure_global_position() -> void:
	super.set_structure_global_position()
	for waypoint: Waypoint in $Waypoints.get_children():
		waypoint.set_structure_global_position()
	for room: Room in $Rooms.get_children():
		room.set_structure_global_position()

# Delete the structure and data related to it
func delete_itself() -> void:
	# Delete all Rooms in the Building
	for room: Room in rooms.get_children():
		await room.delete_itself()
	# Delete all Waypoints in the Building
	for waypoint: Waypoint in waypoints.get_children():
		await waypoint.delete_itself()
	
	var base_map: BaseMap = get_parent().get_parent()
	var buildings_dictionary: Dictionary = Globals.offline_data[base_map.id]['Buildings']
	var _erased: bool = buildings_dictionary.erase(id)
	base_map.update_buildings_time(int(Time.get_unix_time_from_system()))
	
	await Globals.delete_structure(base_map.id + '/Buildings', id)
	self.queue_free()

# Used by Waypoint children to get data
func get_offline_data_waypoints() -> Dictionary:
	var base_map: BaseMap = get_parent().get_parent()
	return Globals.offline_data[base_map.id]['Buildings'][id]['Waypoints']

# Adds in the texture for the building
func add_map_texture() -> void:
	if structure_name in map_textures_dictionary.keys():
		var building_texture_scene: PackedScene = map_textures_dictionary[structure_name]
		var building_texture_node: Node3D = building_texture_scene.instantiate()
		add_child(building_texture_node)
	else:
		print("Not found key: " + structure_name)
		print(map_textures_dictionary)
