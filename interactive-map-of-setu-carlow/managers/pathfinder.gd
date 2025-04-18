extends Node
class_name Pathfinder

# Signal to UI for distance
signal pathfinding_distance(distance: float)
# Turns off the loading panel
signal map_fully_updated()

# Contains { waypoint_id: String, Waypoint: Waypoint }
var _all_waypoints: Dictionary[String, Waypoint] = {}

var final_waypoint: Waypoint


func _ready() -> void:
	Globals.pathfinder = self


func add_new_waypoint(new_waypoint: Waypoint) -> void:
	_all_waypoints[new_waypoint.id] = new_waypoint


func get_waypoint(waypoint_id: String) -> Waypoint:
	return _all_waypoints[waypoint_id]


func remove_waypoint(waypoint_id: String) -> void:
	var _erased: bool = _all_waypoints.erase(waypoint_id)

# Tells the waypoints to create connections
func _on_structure_spawner_all_structures_done() -> void:
	for waypoint: Waypoint in _all_waypoints.values():
		waypoint.update_links(false)
	Globals.base_map.update_visibility()
	map_fully_updated.emit()


func _on_ui_root_cancel_navigation() -> void:
	reset()

# Resets all of the Waypoints values
func reset() -> void:
	if final_waypoint != null:
		final_waypoint.reset()

# Creates path between 2 waypoints
func do_pathfinding(starting_waypoint: Waypoint, end_waypoint: Waypoint, allow_stairs: bool) -> float:
	print("Thinking")
	# Make sure everything is reset
	reset()

	var end_structure: Structure = end_waypoint.get_parent_structure()

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
		if current.get_parent_structure() == end_structure:
			final_waypoint = current
			return current.finish_pathfinding(null, starting_waypoint.get_parent_structure())

		remaining_waypoints_list.erase(current)
		checked_waypoints_list.append(current)

		for neighbour_id: String in current.waypoint_connections.keys():
			if current.waypoint_connections[neighbour_id] == "Closed" or (not allow_stairs and current.waypoint_connections[neighbour_id] == "Stairs"):
				continue

			var neighbour: Waypoint = get_waypoint(neighbour_id)
			if checked_waypoints_list.has(neighbour):
				continue

			print("Neighour: " + neighbour.id)

			var new_waypoint: bool = neighbour not in remaining_waypoints_list
			var new_distance_to_neighbour: float = (
				current.g_cost +
				current.global_position.distance_to(neighbour.global_position) +
				abs(current.floor_number - neighbour.floor_number)
			)
			if current.waypoint_connections[neighbour_id] == 'Elevator':
				new_distance_to_neighbour += 5

			if new_waypoint or new_distance_to_neighbour < neighbour.g_cost:
				neighbour.g_cost = new_distance_to_neighbour
				neighbour.from_waypoint = current

				if new_waypoint:
					neighbour.h_cost = neighbour.global_position.distance_to(end_waypoint.global_position) + abs(neighbour.floor_number - end_waypoint.floor_number)
					remaining_waypoints_list.append(neighbour)

				print("F Cost: " + str(neighbour.f_cost))
				print("G Cost: " + str(neighbour.g_cost))
				print("H Cost: " + str(neighbour.h_cost))

	return 0


func _on_ui_root_start_navigation(from_structure: Structure, to_structure: Structure, allow_stairs: bool) -> void:
	var from_waypoint: Waypoint
	var to_waypoint: Waypoint
	# Get Waypoints for pathfinding
	if from_structure is Room: from_waypoint = (from_structure as Room).get_closest_waypoint()
	elif from_structure is Building: from_waypoint = (from_structure as Building).get_closest_waypoint()
	if to_structure is Room: to_waypoint = (to_structure as Room).get_closest_waypoint()
	elif to_structure is Building: to_waypoint = (to_structure as Building).get_closest_waypoint()

	if from_waypoint != null and to_waypoint != null:
		pathfinding_distance.emit(do_pathfinding(from_waypoint, to_waypoint, allow_stairs))


func get_all_waypoints_by_distance(from_waypoint_id: String) -> Array[String]:
	# Create a Dictionary of waypoints and distances
	var all_waypoints: Dictionary[String, float] = {}
	for waypoint_id: String in _all_waypoints.keys():
		var waypoint: Waypoint = _all_waypoints[waypoint_id]
		var from_waypoint: Waypoint = _all_waypoints[from_waypoint_id]
		all_waypoints[waypoint_id] = from_waypoint.global_position.distance_to(waypoint.global_position) + abs(from_waypoint.floor_number - waypoint.floor_number)

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
