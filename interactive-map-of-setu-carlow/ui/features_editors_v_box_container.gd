extends VBoxContainer

signal add_connection_feature(waypoint_id: String)
signal delete_connection_feature(waypoint_id: String)

@export var attribute_editor_scene: PackedScene

var connected_waypoints_ids_array: Array[String]
var features_array: Array[String]
var all_features_array: Array[String]

var waypoint_id_label_children: Array[Label]


func save_features(connected_waypoints_ids: Array[String], features: Array[String], all_features: Array[String]) -> void:
	connected_waypoints_ids_array = connected_waypoints_ids
	features_array = features
	all_features_array = all_features
	_create_attribute_editors()


func _create_attribute_editors() -> void:
	# Delete old children
	for waypoint_id_label: Label in waypoint_id_label_children:
		waypoint_id_label.queue_free()
	waypoint_id_label_children.clear()
	
	var waypoint_id_label: Label
	var attribute_editor_control: AttributeEditorControl
	var _error: int
	var index: int = 0
	for waypoint_id: String in connected_waypoints_ids_array:
		waypoint_id_label = Label.new()
		waypoint_id_label.text = waypoint_id
		
		attribute_editor_control = attribute_editor_scene.instantiate()
		if features_array[index] != "":
			attribute_editor_control.set_editor_as_read_only(features_array[index])
			_error = attribute_editor_control.connect("delete_attribute", delete_feature)
		else:
			attribute_editor_control.set_editor_as_editable(all_features_array)
			_error = attribute_editor_control.connect("add_attribute", add_feature)
		
		waypoint_id_label_children.append(waypoint_id_label)
		waypoint_id_label.add_child(attribute_editor_control)
		add_child(waypoint_id_label)
		index += 1


func add_feature(feature: String, parent_control: Control) -> void:
	if parent_control is Label:
		var waypoint_id: String = (parent_control as Label).text
		var index: int = connected_waypoints_ids_array.find(waypoint_id)
		features_array[index] = feature


func delete_feature(feature: String, parent_control: Control) -> void:
	if parent_control is Label:
		var waypoint_id: String = (parent_control as Label).text
	pass
