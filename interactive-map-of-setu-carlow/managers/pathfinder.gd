extends Node
class_name Pathfinder

# Contains { waypoint_id: String: Waypoint: Waypoint }
var _all_waypoints: Dictionary = {}

var final_waypoint: Waypoint

func _ready() -> void:
	@warning_ignore("unsafe_property_access")
	Globals.pathfinder = self

func add_new_waypoint(new_waypoint: Waypoint) -> void:
	_all_waypoints[new_waypoint.id] = new_waypoint

func get_waypoint(waypoint_id: String) -> Waypoint:
	return _all_waypoints[waypoint_id]

# Changes edit mode for waypoints
func _on_ui_root_edit_mode_toggled() -> void:
	for waypoint: Waypoint in _all_waypoints.values():
		waypoint.check_toggle()

# Tells the waypoints to create connections
func _on_structure_spawner_all_structures_done() -> void:
	for waypoint: Waypoint in _all_waypoints.values():
		waypoint.activate_links()

# Resets all of the Waypoints values
func reset() -> void:
	if final_waypoint != null:
		final_waypoint.reset()

# Creates path between 2 waypoints
func do_pathfinding(starting_waypoint: Waypoint, end_waypoint: Waypoint) -> void:
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
			current.finish_pathfinding()
			final_waypoint = current
			return
		
		remaining_waypoints_list.erase(current)
		checked_waypoints_list.append(current)
		
		for neighbour_id: String in current.waypoint_connections_ids:
			var neighbour: Waypoint = get_waypoint(neighbour_id)
			if neighbour in checked_waypoints_list:
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
	
	return
