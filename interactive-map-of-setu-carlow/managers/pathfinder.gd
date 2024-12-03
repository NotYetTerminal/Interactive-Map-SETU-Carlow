extends Node
class_name Pathfinder

# Contains { waypoint_id: String: Waypoint: WaypointStructure }
var _all_waypoints: Dictionary = {}

func add_new_waypoint(new_waypoint: WaypointStructure) -> void:
	_all_waypoints[new_waypoint.id] = new_waypoint

func get_waypoint(waypoint_id: String) -> WaypointStructure:
	return _all_waypoints[waypoint_id]


func _on_ui_root_edit_mode_toggled() -> void:
	for waypoint_id: String in _all_waypoints:
		get_waypoint(waypoint_id).check_toggle()
