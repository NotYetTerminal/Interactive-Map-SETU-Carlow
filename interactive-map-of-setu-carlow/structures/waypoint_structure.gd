extends Structure
class_name WaypointStructure

var floor_number: int
var feature_type: String

var parent_id: String
var parent_type: String

var waypoint_connections_ids: Array[String] = []

# Save details from map_data
func save_details(id_in: String, details: Dictionary) -> void:
	id = id_in
	
	longitude = details["longitude"]["doubleValue"]
	latitude = details["latitude"]["doubleValue"]
	
	@warning_ignore("unsafe_call_argument")
	floor_number = int(details["floor_number"]["integerValue"])
	feature_type = details["feature_type"]["stringValue"]
	
	parent_id = details["parent_id"]["stringValue"]
	parent_type = details["parent_type"]["stringValue"]
	
	for id_dict: Dictionary in details["waypoint_connection_ids"]["arrayValue"]["values"]:
		print("Check if correct")
		waypoint_connections_ids.append(id_dict.values()[0])

# Makes waypoints visible on editing
func check_toggle() -> void:
	visible = Globals.edit_mode

# Update the details when editing
func update_details(details: Dictionary) -> void:
	save_details(id, details)
	# Update Waypoint depending on the parent
	var parent_1: Structure = get_parent()
	if parent_1 is BaseMap:
		Globals.offline_data[parent_1.id]['Waypoints'][id] = details
	elif parent_1 is Building:
		var parent_2: BaseMap = parent_1.get_parent()
		Globals.offline_data[parent_2.id]['Buildings'][parent_1.id]['Waypoints'][id] = details
	elif parent_1 is Room:
		var parent_2: Building = parent_1.get_parent()
		var parent_3: BaseMap = parent_2.get_parent()
		Globals.offline_data[parent_3.id]['Buildings'][parent_2.id]['Rooms'][parent_1.id]['Waypoints'][id] = details
	
	parent_1.update_waypoints_time(Time.get_unix_time_from_system())
	
	Globals.save_offline_data()
