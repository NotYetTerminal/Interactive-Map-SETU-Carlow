extends Structure
class_name Building

var building_name: String
var description: String
var building_letter: String

@export var waypoints: Node
@export var rooms: Node

var waypoints_updated_time: int
var rooms_updated_time: int

# Save details from map_data
func save_details(id_in: String, details: Dictionary) -> void:
	id = id_in
	
	longitude = details["longitude"]["doubleValue"]
	latitude = details["latitude"]["doubleValue"]
	
	building_name = details["name"]["stringValue"]
	description = details["description"]["stringValue"]
	building_letter = details["building_letter"]["stringValue"]
	
	@warning_ignore("unsafe_call_argument")
	waypoints_updated_time = int(details["waypoints_updated_time"]["integerValue"])
	@warning_ignore("unsafe_call_argument")
	rooms_updated_time = int(details["rooms_updated_time"]["integerValue"])
	
	set_structure_global_position()

# Update the details when editing
func update_details(details: Dictionary) -> void:
	save_details(id, details)
	var base_map: BaseMap = get_parent().get_parent()
	var building_data: Dictionary = Globals.offline_data[base_map.id]['Buildings'][id]
	
	details['Rooms'] = building_data['Rooms']
	details['Waypoints'] = building_data['Waypoints']
	Globals.offline_data[base_map.id]['Buildings'][id] = details
	base_map.update_buildings_time(Time.get_unix_time_from_system())
	
	Globals.save_offline_data()

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
	global_position = Vector3(longitude - Globals.base_longitude, 0, latitude - Globals.base_latitude)
	for waypoint: Waypoint in $Waypoints.get_children():
		waypoint.set_structure_global_position()
	for room: Room in $Rooms.get_children():
		room.set_structure_global_position()
