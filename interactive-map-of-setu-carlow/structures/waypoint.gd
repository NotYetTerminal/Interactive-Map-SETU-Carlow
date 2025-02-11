extends Structure
class_name Waypoint

var floor_number: int

# Dictionary to contain connections { waypoint_connection_id: String, connection_feature: String }
var waypoint_connections: Dictionary = {}

@export var link_node_3d_scene: PackedScene

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

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
func save_details(id_in: String, details: Dictionary, call_others: bool = true) -> Array[String]:
	# Do not run update_links first time as not all Waypoints are spawned yet
	var previously_empty: bool = id == ""
	id = id_in
	
	# When the structure is created no data is passed to it
	if details.is_empty():
		return []
	
	var waypoint_connections_dictionary: Dictionary = details["waypoint_connections"]
	var changed_fields: Array[String] = [
		"longitude" if longitude != details["longitude"] else "",
		"latitude" if latitude != details["latitude"] else "",
		"floor_number" if floor_number != details["floor_number"] else "",
		"waypoint_connections" if waypoint_connections.hash() != waypoint_connections_dictionary.hash() else ""
	]
	
	longitude = details["longitude"]
	latitude = details["latitude"]
	
	floor_number = details["floor_number"]
	
	waypoint_connections.clear()
	for waypoint_id: String in waypoint_connections_dictionary.keys():
		waypoint_connections[waypoint_id] = waypoint_connections_dictionary[waypoint_id]
	
	if not previously_empty and changed_fields.has("waypoint_connections"):
		update_links(call_others)
	
	set_structure_global_position()
	return changed_fields


func get_parent_structure() -> Structure:
	return get_parent().get_parent()


func update_visibility_by_floor_number(checking_floor_number: int) -> void:
	var should_be_visible: bool = floor_number == checking_floor_number and Globals.edit_mode
	mesh_instance_3d.visible = should_be_visible
	collision_shape_3d.disabled = not should_be_visible
	for link: Link in links_dictionary.values():
		link.set_link_holder_visibility(should_be_visible)
		link.set_texture_visibility(floor_number == checking_floor_number)

# Update the details when editing
func update_details(details: Dictionary, call_others: bool = true) -> void:
	var fields: Array[String] = save_details(id, details, call_others)
	# Update Waypoint depending on the parent
	var parent_structure: Structure = get_parent_structure()
	parent_structure.get_offline_data_waypoints()[id] = details
	await Globals.save_data(id, fields, parent_structure.get_firestore_path() + "/Waypoints", details)
	
	parent_structure.update_waypoints_time(int(Time.get_unix_time_from_system()))

# Delete the structure and data related to it
func delete_itself() -> void:
	var collection_path: String
	
	var parent_1: Structure = get_parent_structure()
	if parent_1 is BaseMap:
		collection_path = parent_1.id + '/Waypoints'
	elif parent_1 is Building:
		var parent_2: BaseMap = parent_1.get_parent_structure()
		collection_path = parent_2.id + '/Buildings/' + parent_1.id + '/Waypoints'
	elif parent_1 is Room:
		var parent_2: Building = parent_1.get_parent_structure()
		var parent_3: BaseMap = parent_2.get_parent_structure()
		collection_path = parent_3.id + '/Buildings/' + parent_2.id + '/Rooms/' + parent_1.id + '/Waypoints'
	
	var waypoints_dictionary: Dictionary = parent_1.get_offline_data_waypoints()
	var _erased: bool = waypoints_dictionary.erase(id)
	parent_1.update_waypoints_time(int(Time.get_unix_time_from_system()))
	
	# Delete connections with other Waypoints
	for waypoint_id: String in waypoint_connections.keys():
		var waypoint: Waypoint = Globals.pathfinder.get_waypoint(waypoint_id)
		waypoint.remove_connection(id)
	
	await Globals.delete_structure(collection_path, id)
	Globals.pathfinder.remove_waypoint(id)
	self.queue_free()

# Removes the id passed in from the connections
func remove_connection(id_to_remove: String) -> void:
	# Update parent structure Waypoints time
	var parent_structure: Structure = get_parent_structure()
	parent_structure.update_waypoints_time(int(Time.get_unix_time_from_system()))
	
	# Remove from connections
	var _result: bool = waypoint_connections.erase(id_to_remove)
	var structure_data: Dictionary = parent_structure.get_offline_data_waypoints()[id]
	var global_data_connections_array: Array = structure_data['waypoint_connections']
	global_data_connections_array.erase(id_to_remove)
	
	# Update save data
	await Globals.save_data(id, ["waypoint_connections"], parent_structure.get_firestore_path() + "/Waypoints", structure_data)
	
	# Remove graphical link
	if links_dictionary.has(id_to_remove):
		var link_node: Node3D = links_dictionary[id_to_remove]
		var _erased: bool = links_dictionary.erase(id_to_remove)
		link_node.queue_free()

# Called to activate the links of this waypoint
# May call on connections to do the same
func update_links(call_others: bool) -> void:
	var link: Link
	var target_waypoint: Waypoint
	var feature: String
	# Adding new links
	for waypoint_id: String in waypoint_connections.keys():
		target_waypoint = Globals.pathfinder.get_waypoint(waypoint_id)
		if not links_dictionary.has(waypoint_id):
			link = link_node_3d_scene.instantiate()
			add_child(link)
			links_dictionary[waypoint_id] = link
		else:
			link = links_dictionary[waypoint_id]
		
		# For the other Waypoint add the current id
		feature = waypoint_connections[waypoint_id]
		if call_others:
			target_waypoint.add_waypoint(id, feature)
		# TODO Maybe don't have both link textures showing
		link.set_target_waypoint_and_feature(target_waypoint, feature)
		link.set_link_holder_visibility(Globals.edit_mode)
	
	# Deleting links
	var remove_links_waypoint_ids: Array[String] = []
	for waypoint_id: String in links_dictionary.keys():
		target_waypoint = Globals.pathfinder.get_waypoint(waypoint_id)
		if not waypoint_connections.has(waypoint_id):
			remove_links_waypoint_ids.append(waypoint_id)
			# For the other Waypoint delete the current id
			if call_others:
				target_waypoint.delete_waypoint(id)
	
	var _result: bool
	for waypoint_id: String in remove_links_waypoint_ids:
		link = links_dictionary[waypoint_id]
		link.queue_free()
		_result = links_dictionary.erase(waypoint_id)


func add_waypoint(waypoint_id: String, feature: String) -> void:
	var details: Dictionary = _collect_details()
	var waypoint_connections_dictionary: Dictionary = details['waypoint_connections']
	if not waypoint_connections.has(waypoint_id) or waypoint_connections_dictionary[waypoint_id] != feature:
		waypoint_connections_dictionary[waypoint_id] = feature
		update_details(details, false)


func delete_waypoint(waypoint_id: String) -> void:
	if waypoint_connections.has(waypoint_id):
		var details: Dictionary = _collect_details()
		var waypoint_connections_dictionary: Dictionary = details['waypoint_connections']
		var _result: bool = waypoint_connections_dictionary.erase(waypoint_id)
		update_details(details, false)


func _collect_details() -> Dictionary:
	var waypoint_connections_dictionary: Dictionary = {}
	for waypoint_id: String in waypoint_connections.keys():
		waypoint_connections_dictionary[waypoint_id] = waypoint_connections[waypoint_id]
	return {
		'id': id,
		'longitude': longitude,
		'latitude': latitude,
		'floor_number': floor_number,
		'waypoint_connections': waypoint_connections_dictionary
	}

# Change the colour of the Waypoint
func change_colour(new_colour: Color) -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = new_colour
	var mesh_instance: MeshInstance3D = $MeshInstance3D
	mesh_instance.set_surface_override_material(0, material)

# Change the colour of the Link between Waypoints
func change_link_colour(waypoint_id: String, new_colour: Color) -> void:
	if links_dictionary.has(waypoint_id):
		var link: Link = links_dictionary[waypoint_id]
		link.change_colour(new_colour)
		if new_colour == Color.LIGHT_GREEN:
			link.set_link_holder_visibility(true)
		else:
			link.set_link_holder_visibility(false)
	else:
		print("Link not found!")

# Change the colour of Link and signal to next Waypoint
func finish_pathfinding(to_waypoint: Waypoint = null) -> float:
	var distance: float = 0
	if from_waypoint != null:
		change_link_colour(from_waypoint.id, Color.LIGHT_GREEN)
		distance += from_waypoint.finish_pathfinding(self)
	# This will run for everyone except the target
	if to_waypoint != null:
		change_link_colour(to_waypoint.id, Color.LIGHT_GREEN)
		distance += calculate_distance_to_waypoint(to_waypoint)
	mesh_instance_3d.visible = true
	return distance


func calculate_distance_to_waypoint(to_waypoint: Waypoint) -> float:
	# Convert to radians
	var end_lon_radian: float = deg_to_rad(to_waypoint.longitude)
	var end_lat_radian: float = deg_to_rad(to_waypoint.latitude)
	var start_lon_radian: float = deg_to_rad(longitude)
	var start_lat_radian: float = deg_to_rad(latitude)
	
	# Calculate distance using Pythagoras’ theorem and equi­rectangular projec­tion
	var x_distance: float = (end_lon_radian - start_lon_radian) * cos((start_lat_radian + start_lat_radian) / 2)
	var y_distance: float = end_lat_radian - start_lat_radian
	var distance: float = sqrt(x_distance*x_distance + y_distance*y_distance) * Globals.EARTH_RADIUS
	# Round distance to 2 decimal places
	return round(distance * 100) / 100

# Reset pathfinding variables and colour
func reset(to_waypoint: Waypoint = null) -> void:
	if from_waypoint != null:
		change_link_colour(from_waypoint.id, Color.LIGHT_SALMON)
	# This will run for everyone except the target
	if to_waypoint != null:
		change_link_colour(to_waypoint.id, Color.LIGHT_SALMON)
	
	mesh_instance_3d.visible = false
	
	# Reset values
	g_cost = 0
	h_cost = 0
	var temp_from_waypoint: Waypoint = from_waypoint
	from_waypoint = null
	
	# Run for each waypoint with a connection
	for waypoint_id : String in waypoint_connections.keys():
		var waypoint: Waypoint = Globals.pathfinder.get_waypoint(waypoint_id)
		# Only run if values changed or final waypoint
		if waypoint.from_waypoint != null or waypoint == temp_from_waypoint:
			waypoint.reset(self)
