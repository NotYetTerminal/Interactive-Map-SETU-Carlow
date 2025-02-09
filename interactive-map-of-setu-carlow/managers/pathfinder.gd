extends Node
class_name Pathfinder

# Signal to UI for distance
signal pathfinding_distance(distance: float)

# Contains { waypoint_id: String: Waypoint: Waypoint }
var _all_waypoints: Dictionary = {}

var final_waypoint: Waypoint

func _ready() -> void:
	Globals.pathfinder = self

func add_new_waypoint(new_waypoint: Waypoint) -> void:
	_all_waypoints[new_waypoint.id] = new_waypoint

func get_waypoint(waypoint_id: String) -> Waypoint:
	return _all_waypoints[waypoint_id]

func remove_waypoint(waypoint_id: String) -> void:
	var _erased: bool = _all_waypoints.erase(waypoint_id)

# Changes edit mode for waypoints
func _on_admin_check_button_edit_mode_toggled() -> void:
	for waypoint: Waypoint in _all_waypoints.values():
		waypoint.check_toggle()

# Tells the waypoints to create connections
func _on_structure_spawner_all_structures_done() -> void:
	for waypoint: Waypoint in _all_waypoints.values():
		waypoint.update_links(false)


func _on_user_ui_root_cancel_navigation() -> void:
	reset()

# Resets all of the Waypoints values
func reset() -> void:
	if final_waypoint != null:
		final_waypoint.reset()

# Creates path between 2 waypoints
func do_pathfinding(starting_waypoint: Waypoint, end_waypoint: Waypoint) -> float:
	print("Thinking")
	# Make sure everything is reset
	reset()
	
	var remaining_waypoints_list: Array[Waypoint] = [starting_waypoint]
	var checked_waypoints_list: Array[Waypoint] = []
	
	var current: Waypoint
	while len(remaining_waypoints_list) != 0:
		current = remaining_waypoints_list[0]
		for waypoint: Waypoint in remaining_waypoints_list:
			if waypoint.f_cost < current.f_cost or (
				waypoint.f_cost == current.f_cost and
				waypoint.h_cost < current.h_cost
			):
				current = waypoint
		
		print("\nChecking " + current.id)
		if current == end_waypoint:
			final_waypoint = current
			return current.finish_pathfinding()
		
		remaining_waypoints_list.erase(current)
		checked_waypoints_list.append(current)
		
		for neighbour_id: String in current.waypoint_connections.keys():
			var neighbour: Waypoint = get_waypoint(neighbour_id)
			if checked_waypoints_list.has(neighbour):
				continue
			
			print("Neighour: " + neighbour.id)
			
			var new_waypoint: bool = neighbour not in remaining_waypoints_list
			var new_distance_to_neighbour: float = (
				current.g_cost +
				current.global_position.distance_to(neighbour.global_position)
			)
			
			if new_waypoint or new_distance_to_neighbour < neighbour.g_cost:
				neighbour.g_cost = new_distance_to_neighbour
				neighbour.from_waypoint = current
				
				if new_waypoint:
					neighbour.h_cost = neighbour.global_position.distance_to(end_waypoint.global_position)
					remaining_waypoints_list.append(neighbour)
				
				print("F Cost: " + str(neighbour.f_cost))
				print("G Cost: " + str(neighbour.g_cost))
				print("H Cost: " + str(neighbour.h_cost))
	
	return 0


func _on_user_ui_root_start_navigation(from_structure: Structure, to_structure: Structure) -> void:
	var from_waypoint: Waypoint
	var to_waypoint: Waypoint
	# Get Waypoints for pathfinding
	if from_structure is Room: from_waypoint = (from_structure as Room).get_closest_waypoint()
	elif from_structure is Building: from_waypoint = (from_structure as Building).get_closest_waypoint()
	if to_structure is Room: to_waypoint = (to_structure as Room).get_closest_waypoint()
	elif to_structure is Building: to_waypoint = (to_structure as Building).get_closest_waypoint()
	
	if from_waypoint != null and to_waypoint != null:
		pathfinding_distance.emit(do_pathfinding(from_waypoint, to_waypoint))


func _on_screen_elements_control_update_floor_number(floor_number: int) -> void:
	Globals.base_map.update_visibility_by_floor_number(floor_number)

# TODO Sorting is incorrect
func get_all_waypoints_by_distance(from_waypoint_id: String) -> Array[String]:
	# Create a Dictionary of waypoints and distances
	var all_waypoints: Dictionary = {}
	for waypoint_id: String in _all_waypoints.keys():
		var waypoint: Waypoint = _all_waypoints[waypoint_id]
		var from_waypoint: Waypoint = _all_waypoints[from_waypoint_id]
		all_waypoints[waypoint_id] = from_waypoint.global_position.distance_to(waypoint.global_position)
	
	# Sort the Waypoints by distance
	var sorted_waypoints: Array[String] = []
	var smallest_waypoint_id: String = ''
	var smallest_distance: float = 1000000000
	var all_waypoints_keys: Array = all_waypoints.keys()
	while true:
		for waypoint_id: String in all_waypoints_keys:
			var waypoint_distance: float = all_waypoints[waypoint_id]
			if waypoint_distance < smallest_distance:
				smallest_distance = waypoint_distance
				smallest_waypoint_id = waypoint_id
		
		sorted_waypoints.append(smallest_waypoint_id)
		smallest_distance = 1000000000
		var _result: bool = all_waypoints.erase(smallest_waypoint_id)
		if all_waypoints.is_empty():
			break
		all_waypoints_keys = all_waypoints.keys()
	
	sorted_waypoints.erase(from_waypoint_id)
	return sorted_waypoints
