extends Structure
class_name Room

var floor_number: int
var parent_id: String

var room_name: String
var description: String
var lectures: String

var waypoints_updated_time: int

@export var waypoints: Node

# Save details from map_data
func save_details(id_in: String, details: Dictionary) -> Array[String]:
	@warning_ignore("unsafe_call_argument")
	var changed_fields: Array[String] = [
		"longitude" if longitude != details["longitude"]["doubleValue"] else "",
		"latitude" if latitude != details["latitude"]["doubleValue"] else "",
		"floor_number" if floor_number != int(details["floor_number"]["integerValue"]) else "",
		"name" if room_name != details["name"]["stringValue"] else "",
		"description" if description != details["description"]["stringValue"] else "",
		"lecturers" if lectures != details["lecturers"]["stringValue"] else "",
		"waypoints_updated_time" if waypoints_updated_time != int(details["waypoints_updated_time"]["integerValue"]) else ""
	]
	id = id_in
	
	longitude = details["longitude"]["doubleValue"]
	latitude = details["latitude"]["doubleValue"]
	
	@warning_ignore("unsafe_call_argument")
	floor_number = int(details["floor_number"]["integerValue"])
	parent_id = details["parent_id"]["stringValue"]
	
	room_name = details["name"]["stringValue"]
	description = details["description"]["stringValue"]
	lectures = details["lecturers"]["stringValue"]
	
	@warning_ignore("unsafe_call_argument")
	waypoints_updated_time = int(details["waypoints_updated_time"]["integerValue"])
	
	set_structure_global_position()
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
	
	Globals.save_data(id, fields)

# Used by children to update time
func update_waypoints_time(new_time: int) -> void:
	waypoints_updated_time = new_time
	var building: Building = get_parent().get_parent()
	var base_map: BaseMap = building.get_parent().get_parent()
	Globals.offline_data[base_map.id]['Buildings'][building.id]['Rooms'][id]['waypoints_updated_time'] = {'integerValue': str(waypoints_updated_time)}
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
