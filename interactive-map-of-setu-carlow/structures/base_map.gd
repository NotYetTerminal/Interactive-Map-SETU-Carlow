extends Structure
class_name BaseMap

@export var waypoints: Node
@export var buildings: Node

var waypoints_updated_time: int
var buildings_updated_time: int

# Save details from map_data
func save_details(id_in: String, details: Dictionary) -> void:
	id = id_in
	
	longitude = details["longitude"]["doubleValue"]
	latitude = details["latitude"]["doubleValue"]
	
	@warning_ignore("unsafe_call_argument")
	waypoints_updated_time = int(details["waypoints_updated_time"]["integerValue"])
	@warning_ignore("unsafe_call_argument")
	buildings_updated_time = int(details["buildings_updated_time"]["integerValue"])

# Update the details when editing
func update_details(details: Dictionary) -> void:
	save_details(id, details)
	var base_map_data: Dictionary = Globals.offline_data[id]
	details['Buildings'] = base_map_data['Buildings']
	details['Waypoints'] = base_map_data['Waypoints']
	Globals.offline_data[id] = details
	Globals.save_offline_data()

# Used by children to update time
func update_buildings_time(new_time: int) -> void:
	buildings_updated_time = new_time
	Globals.offline_data[id]['buildings_updated_time'] = buildings_updated_time

func update_waypoints_time(new_time: int) -> void:
	waypoints_updated_time = new_time
	Globals.offline_data[id]['waypoints_updated_time'] = waypoints_updated_time
