extends VBoxContainer
class_name WaypointConnectionsIDsEditorsVBoxContainer

signal add_connection_waypoint_id(waypoint_id: String)
signal delete_connection_waypoint_id(waypoint_id: String)

@export var attribute_editor_scene: PackedScene

var connected_waypoints_ids_array: Array[String]
var all_waypoints_ids_array: Array[String]

var attribute_editor_children: Array[AttributeEditorControl]
var new_attribute_editor_child: AttributeEditorControl


func _ready() -> void:
	new_attribute_editor_child = attribute_editor_scene.instantiate()
	add_child(new_attribute_editor_child)


func save_waypoints_ids(connected_waypoints_ids: Array[String], all_waypoints_ids: Array[String]) -> void:
	connected_waypoints_ids_array = connected_waypoints_ids
	all_waypoints_ids_array = all_waypoints_ids
	_create_attribute_editors()


func _create_attribute_editors() -> void:
	# Delete old children
	for attribute_editor_control: AttributeEditorControl in attribute_editor_children:
		attribute_editor_control.queue_free()
	attribute_editor_children.clear()
	
	var attribute_editor_control: AttributeEditorControl
	var _error: int
	for waypoint_id: String in connected_waypoints_ids_array:
		attribute_editor_control = attribute_editor_scene.instantiate()
		
		attribute_editor_control.set_editor_as_read_only(waypoint_id)
		_error = attribute_editor_control.connect("delete_attribute", delete_waypoint_id)
		
		attribute_editor_children.append(attribute_editor_control)
		add_child(attribute_editor_control)
	
	new_attribute_editor_child.set_editor_as_editable(all_waypoints_ids_array, connected_waypoints_ids_array)
	_error = new_attribute_editor_child.connect("add_attribute", add_waypoint_id)


func add_waypoint_id(waypoint_id: String, _parent_control: Control) -> void:
	connected_waypoints_ids_array.append(waypoint_id)
	# Change old editor into read only
	new_attribute_editor_child.set_editor_as_read_only(waypoint_id)
	# Make new one
	new_attribute_editor_child = attribute_editor_scene.instantiate()
	new_attribute_editor_child.set_editor_as_editable(all_waypoints_ids_array, connected_waypoints_ids_array)
	add_child(new_attribute_editor_child)
	
	add_connection_waypoint_id.emit(waypoint_id)


func delete_waypoint_id(waypoint_id: String, _parent_control: Control) -> void:
	connected_waypoints_ids_array.erase(waypoint_id)
	new_attribute_editor_child.set_editor_as_editable(all_waypoints_ids_array, connected_waypoints_ids_array)
	delete_connection_waypoint_id.emit(waypoint_id)
