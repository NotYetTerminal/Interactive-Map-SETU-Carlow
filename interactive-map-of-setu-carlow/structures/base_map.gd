extends Structure
class_name BaseMap

@export var waypoints: Node
@export var buildings: Node

var waypoints_updated_time: int
var buildings_updated_time: int

# Save details from map_data
func save_details(id_in: String, details: Dictionary) -> Array[String]:
	@warning_ignore("unsafe_call_argument")
	var changed_fields: Array[String] = [
		"longitude" if longitude != details["longitude"]["doubleValue"] else "",
		"latitude" if latitude != details["latitude"]["doubleValue"] else "",
		"waypoints_updated_time" if waypoints_updated_time != int(details["waypoints_updated_time"]["integerValue"]) else "",
		"buildings_updated_time" if buildings_updated_time != int(details["buildings_updated_time"]["integerValue"]) else ""
	]
	id = id_in
	
	longitude = details["longitude"]["doubleValue"]
	latitude = details["latitude"]["doubleValue"]
	
	@warning_ignore("unsafe_call_argument")
	waypoints_updated_time = int(details["waypoints_updated_time"]["integerValue"])
	@warning_ignore("unsafe_call_argument")
	buildings_updated_time = int(details["buildings_updated_time"]["integerValue"])
	
	set_structure_global_position()
	return changed_fields

# Update the details when editing
func update_details(details: Dictionary) -> void:
	var fields: Array[String] = save_details(id, details)
	var base_map_data: Dictionary = Globals.offline_data[id]
	details['Buildings'] = base_map_data['Buildings']
	details['Waypoints'] = base_map_data['Waypoints']
	
	Globals.offline_data[id] = details
	Globals.save_data(id, fields)

# Used by children to update time
func update_buildings_time(new_time: int) -> void:
	buildings_updated_time = new_time
	Globals.offline_data[id]['buildings_updated_time'] = {'integerValue': str(buildings_updated_time)}

func update_waypoints_time(new_time: int) -> void:
	waypoints_updated_time = new_time
	Globals.offline_data[id]['waypoints_updated_time'] = {'integerValue': str(waypoints_updated_time)}

# Used by Waypoint children to get data
func get_offline_data_waypoints() -> Dictionary:
	return Globals.offline_data[id]['Waypoints']

# Set global position, and update children
func set_structure_global_position() -> void:
	super.set_structure_global_position()
	for waypoint: Waypoint in $Waypoints.get_children():
		waypoint.set_structure_global_position()
	for building: Building in $Buildings.get_children():
		building.set_structure_global_position()
