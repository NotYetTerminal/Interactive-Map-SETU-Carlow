extends VBoxContainer
class_name WaypointConnectionsEditorsVBoxContainer

signal add_connection_waypoint_id(waypoint_id: String)
signal delete_connection_waypoint_id(waypoint_id: String)
signal update_connection_feature(waypoint_id: String, feature: String)

@export var waypoint_connection_editor_scene: PackedScene

var connected_waypoints_dictionary: Dictionary[String, String]
var all_waypoints_ids_array: Array[String]

var waypoint_connection_editor_children: Array[WaypointConnectionEditorControl]
var new_waypoint_connection_editor_child: WaypointConnectionEditorControl


func save_waypoints_ids(connected_waypoints: Dictionary[String, String], all_waypoints_ids: Array[String]) -> void:
	connected_waypoints_dictionary.clear()
	for waypoint_id: String in connected_waypoints.keys():
		connected_waypoints_dictionary[waypoint_id] = connected_waypoints[waypoint_id]
	all_waypoints_ids_array = all_waypoints_ids
	_create_attribute_editors()


func _create_attribute_editors() -> void:
	# Delete old children
	if new_waypoint_connection_editor_child != null:
		new_waypoint_connection_editor_child.queue_free()
	for waypoint_connection_editor_control: WaypointConnectionEditorControl in waypoint_connection_editor_children:
		if waypoint_connection_editor_control != null:
			waypoint_connection_editor_control.queue_free()
	waypoint_connection_editor_children.clear()
	
	var waypoint_connection_editor_control: WaypointConnectionEditorControl
	var _error: int
	for waypoint_id: String in connected_waypoints_dictionary.keys():
		waypoint_connection_editor_control = waypoint_connection_editor_scene.instantiate()
		add_child(waypoint_connection_editor_control)
		
		var selected_feature: String = connected_waypoints_dictionary[waypoint_id]
		waypoint_connection_editor_control.set_waypoint_editor_as_read_only(waypoint_id, selected_feature)
		_error = waypoint_connection_editor_control.connect("add_connection", add_waypoint_id)
		_error = waypoint_connection_editor_control.connect("delete_connection", delete_waypoint_id)
		_error = waypoint_connection_editor_control.connect("change_feature", change_connection_feature)
		
		waypoint_connection_editor_children.append(waypoint_connection_editor_control)
	
	new_waypoint_connection_editor_child = waypoint_connection_editor_scene.instantiate()
	add_child(new_waypoint_connection_editor_child)
	_error = new_waypoint_connection_editor_child.connect("add_connection", add_waypoint_id)
	_error = new_waypoint_connection_editor_child.connect("delete_connection", delete_waypoint_id)
	_error = new_waypoint_connection_editor_child.connect("change_feature", change_connection_feature)
	new_waypoint_connection_editor_child.set_waypoint_editor_as_editable(connected_waypoints_dictionary, all_waypoints_ids_array)


func add_waypoint_id(waypoint_id: String) -> void:
	connected_waypoints_dictionary[waypoint_id] = 'None'
	# Change old editor into read only
	var selected_feature: String = connected_waypoints_dictionary[waypoint_id]
	new_waypoint_connection_editor_child.set_waypoint_editor_as_read_only(waypoint_id, selected_feature)
	waypoint_connection_editor_children.append(new_waypoint_connection_editor_child)
	# Make new one
	new_waypoint_connection_editor_child = waypoint_connection_editor_scene.instantiate()
	var _error: int = new_waypoint_connection_editor_child.connect("add_connection", add_waypoint_id)
	_error = new_waypoint_connection_editor_child.connect("delete_connection", delete_waypoint_id)
	_error = new_waypoint_connection_editor_child.connect("change_feature", change_connection_feature)
	add_child(new_waypoint_connection_editor_child)
	new_waypoint_connection_editor_child.set_waypoint_editor_as_editable(connected_waypoints_dictionary, all_waypoints_ids_array)
	
	add_connection_waypoint_id.emit(waypoint_id)


func delete_waypoint_id(waypoint_id: String) -> void:
	var _result: bool = connected_waypoints_dictionary.erase(waypoint_id)
	new_waypoint_connection_editor_child.set_waypoint_editor_as_editable(connected_waypoints_dictionary, all_waypoints_ids_array)
	delete_connection_waypoint_id.emit(waypoint_id)


func change_connection_feature(waypoint_id: String, new_feature: String) -> void:
	connected_waypoints_dictionary[waypoint_id] = new_feature
	update_connection_feature.emit(waypoint_id, new_feature)
