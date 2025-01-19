extends Structure
class_name Room

var structure_name: String
var description: String
var lectures: String

var floor_number: int
var parent_id: String

var waypoints_updated_time: int

@export var waypoints: Node

# Save details from map_data
func save_details(id_in: String, details: Dictionary) -> Array[String]:
	id = id_in
	
	# When the structure is created no data is passed to it
	if details.is_empty():
		return []
	
	longitude = details["longitude"]
	latitude = details["latitude"]
	
	structure_name = details["name"]
	description = details["description"]
	lectures = details["lecturers"]
	
	floor_number = details["floor_number"]
	parent_id = details["parent_id"]
	
	waypoints_updated_time = details["waypoints_updated_time"]
	
	set_structure_global_position()
	
	var changed_fields: Array[String] = [
		"longitude" if longitude != details["longitude"] else "",
		"latitude" if latitude != details["latitude"] else "",
		"name" if structure_name != details["name"] else "",
		"description" if description != details["description"] else "",
		"lecturers" if lectures != details["lecturers"] else "",
		"floor_number" if floor_number != details["floor_number"] else "",
		"waypoints_updated_time" if waypoints_updated_time != details["waypoints_updated_time"] else ""
	]
	return changed_fields

# Update the details when editing
func update_details(details: Dictionary) -> void:
	var fields: Array[String] = save_details(id, details)
	var building: Building = get_parent().get_parent()
	var base_map: BaseMap = building.get_parent().get_parent()
	var room_data: Dictionary = Globals.offline_data[base_map.id]['Buildings'][building.id]['Rooms'][id]
	
	details['Waypoints'] = room_data['Waypoints']
	Globals.offline_data[base_map.id]['Buildings'][building.id]['Rooms'][id] = details
	building.update_rooms_time(int(Time.get_unix_time_from_system()))
	
	Globals.save_data(id, fields, building.id)

# Used by children to update time
func update_waypoints_time(new_time: int) -> void:
	waypoints_updated_time = new_time
	var building: Building = get_parent().get_parent()
	var base_map: BaseMap = building.get_parent().get_parent()
	Globals.offline_data[base_map.id]['Buildings'][building.id]['Rooms'][id]['waypoints_updated_time'] = waypoints_updated_time
	building.update_rooms_time(waypoints_updated_time)

# Set global position, and update children
func set_structure_global_position() -> void:
	super.set_structure_global_position()
	for waypoint: Waypoint in $Waypoints.get_children():
		waypoint.set_structure_global_position()

# Delete the structure and data related to it
func delete_itself() -> void:
	# Delete all Waypoints in the Rooms
	for waypoint: Waypoint in waypoints.get_children():
		await waypoint.delete_itself()
	
	var building: Building = get_parent().get_parent()
	var base_map: BaseMap = building.get_parent().get_parent()
	var rooms_dictionary: Dictionary = Globals.offline_data[base_map.id]['Buildings'][building.id]['Rooms']
	var _erased: bool = rooms_dictionary.erase(id)
	building.update_rooms_time(int(Time.get_unix_time_from_system()))
	
	await Globals.delete_structure(base_map.id + '/Buildings/' + building.id + '/Rooms', id)
	self.queue_free()

# Used by Waypoint children to get data
func get_offline_data_waypoints() -> Dictionary:
	var building: Building = get_parent().get_parent()
	var base_map: BaseMap = building.get_parent().get_parent()
	return Globals.offline_data[base_map.id]['Buildings'][building.id]['Rooms'][id]['Waypoints']
