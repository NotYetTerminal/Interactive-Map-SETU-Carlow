extends Structure
class_name Waypoint

var floor_number: int
var feature_type: String

var parent_id: String
var parent_type: String

var waypoint_connections_ids: Array[String] = []

@export var link_node_3d_scene: PackedScene

# Contains a link for each connection { waypoint_id: String, link: Node3D }
var links_dictionary: Dictionary = {}

# Pathfinding variables
var f_cost: float:
	get:
		return g_cost + h_cost
var g_cost: float
var h_cost: float
var from_waypoint: Waypoint

# Save details from map_data
func save_details(id_in: String, details: Dictionary) -> Array[String]:
	@warning_ignore("unsafe_call_argument")
	var changed_fields: Array[String] = [
		"longitude" if longitude != details["longitude"]["doubleValue"] else "",
		"latitude" if latitude != details["latitude"]["doubleValue"] else "",
		"floor_number" if floor_number != int(details["floor_number"]["integerValue"]) else "",
		"feature_type" if feature_type != details["feature_type"]["stringValue"] else "",
		"waypoint_connections_ids"
	]
	id = id_in
	
	longitude = details["longitude"]["doubleValue"]
	latitude = details["latitude"]["doubleValue"]
	
	@warning_ignore("unsafe_call_argument")
	floor_number = int(details["floor_number"]["integerValue"])
	feature_type = details["feature_type"]["stringValue"]
	
	parent_id = details["parent_id"]["stringValue"]
	parent_type = details["parent_type"]["stringValue"]
	
	waypoint_connections_ids = []
	for id_dict: Dictionary in details["waypoint_connections_ids"]["arrayValue"]["values"]:
		waypoint_connections_ids.append(id_dict.values()[0])
	
	set_structure_global_position()
	return changed_fields

# Makes waypoints visible on editing
func check_toggle() -> void:
	#$MeshInstance3D.visible = Globals.edit_mode
	#$CollisionShape3D.disabled = not Globals.edit_mode
	pass

# Update the details when editing
func update_details(details: Dictionary) -> void:
	var fields: Array[String] = save_details(id, details)
	# Update Waypoint depending on the parent
	var parent_structure: Structure = get_parent().get_parent()
	parent_structure.get_offline_data_waypoints()[id] = details
	parent_structure.update_waypoints_time(int(Time.get_unix_time_from_system()))
	
	Globals.save_data(id, fields)

# Delete the structure and data related to it
func delete_itself() -> void:
	var collection_path: String
	
	var parent_1: Structure = get_parent().get_parent()
	if parent_1 is BaseMap:
		collection_path = parent_1.id + '/Waypoints'
	elif parent_1 is Building:
		var parent_2: BaseMap = parent_1.get_parent().get_parent()
		collection_path = parent_2.id + '/Buildings/' + parent_1.id + '/Waypoints'
	elif parent_1 is Room:
		var parent_2: Building = parent_1.get_parent().get_parent()
		var parent_3: BaseMap = parent_2.get_parent().get_parent()
		collection_path = parent_3.id + '/Buildings/' + parent_2.id + '/Rooms/' + parent_1.id + '/Waypoints'
	
	var waypoints_dictionary: Dictionary = parent_1.get_offline_data_waypoints()
	var _erased: bool = waypoints_dictionary.erase(id)
	parent_1.update_waypoints_time(int(Time.get_unix_time_from_system()))
	
	# Delete connections with other Waypoints
	for waypoint_id: String in waypoint_connections_ids:
		var waypoint: Waypoint = Globals.pathfinder.get_waypoint(waypoint_id)
		waypoint.remove_connection(id)
	
	await Globals.delete_structure(collection_path, id)
	Globals.pathfinder.remove_waypoint(id)
	self.queue_free()

# Removes the id passed in from the connections
func remove_connection(id_to_remove: String) -> void:
	# Update parent structure Waypoints time
	var parent_structure: Structure = get_parent().get_parent()
	parent_structure.update_waypoints_time(int(Time.get_unix_time_from_system()))
	# Remove from connections
	waypoint_connections_ids.erase(id_to_remove)
	var global_data_connections_array: Array = parent_structure.get_offline_data_waypoints()[id]['waypoint_connections_ids']['arrayValue']['values']
	var deletion_dictionary: Dictionary
	for connection_dictionary: Dictionary in global_data_connections_array:
		if connection_dictionary['stringValue'] == id_to_remove:
			deletion_dictionary = connection_dictionary
			break
	global_data_connections_array.erase(deletion_dictionary)
	# Update save data
	Globals.save_data(id, ["waypoint_connections_ids"])
	
	# Remove graphical link
	var link_node: Node3D = links_dictionary[id_to_remove]
	var _erased: bool = links_dictionary.erase(id_to_remove)
	link_node.queue_free()

# Called to activate the links of this waypoint
# May call on connections to do the same
func activate_links() -> void:
	for waypoint_id: String in waypoint_connections_ids:
		var target_waypoint: Waypoint = Globals.pathfinder.get_waypoint(waypoint_id)
		# Create new link for connection
		if waypoint_id not in links_dictionary:
			var new_link: Link = link_node_3d_scene.instantiate()
			new_link.target_waypoint = target_waypoint
			add_child(new_link)
			links_dictionary[waypoint_id] = new_link

# Change the colour of the Waypoint
func change_colour(new_colour: Color) -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = new_colour
	var mesh_instance: MeshInstance3D = $CollisionShape3D/MeshInstance3D
	mesh_instance.set_surface_override_material(0, material)

# Change the colour of the Link between Waypoints
func change_link_colour(waypoint_id: String, new_colour: Color) -> void:
	if waypoint_id in links_dictionary.keys():
		var link: Link = links_dictionary[waypoint_id]
		link.change_colour(new_colour)
	else:
		print("Link not found!")

# Change the colour of Link and signal to next Waypoint
func finish_pathfinding(to_waypoint: Waypoint = null) -> void:
	if from_waypoint != null:
		change_link_colour(from_waypoint.id, Color.LIGHT_GREEN)
		from_waypoint.finish_pathfinding(self)
	# This will run for everyone except the target
	if to_waypoint != null:
		change_link_colour(to_waypoint.id, Color.LIGHT_GREEN)

# Reset pathfinding variables and colour
func reset(to_waypoint: Waypoint = null) -> void:
	if from_waypoint != null:
		change_link_colour(from_waypoint.id, Color.LIGHT_SALMON)
	# This will run for everyone except the target
	if to_waypoint != null:
		change_link_colour(to_waypoint.id, Color.LIGHT_SALMON)
	
	# Reset values
	g_cost = 0
	h_cost = 0
	var temp_from_waypoint: Waypoint = from_waypoint
	from_waypoint = null
	
	# Run for each waypoint with a connection
	for waypoint_id : String in waypoint_connections_ids:
		var waypoint: Waypoint = Globals.pathfinder.get_waypoint(waypoint_id)
		# Only run if values changed or final waypoint
		if waypoint.from_waypoint != null or waypoint == temp_from_waypoint:
			waypoint.reset(self)
	
