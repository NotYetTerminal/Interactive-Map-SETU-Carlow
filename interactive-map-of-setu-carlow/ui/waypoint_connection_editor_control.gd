extends Control
class_name WaypointConnectionEditorControl

signal add_connection(waypoint_id: String)
signal delete_connection(waypoint_id: String)
signal change_feature(waypoint_id: String, new_feature: String)

@onready var waypoint_option_button: OptionButton = $HBoxContainer/VBoxContainer/WaypointOptionButton
@onready var editor_button: EditorButton = $HBoxContainer/EditorButton
@onready var feature_option_button: OptionButton = $HBoxContainer/VBoxContainer/FeatureOptionButton

var delete_button_active: bool = false

const ALL_FEATURES: Array[String] = ['None', 'Stairs', 'Closed', 'Elevator']


func set_waypoint_editor_as_read_only(waypoint_id: String, selected_feature: String) -> void:
	waypoint_option_button.clear()
	waypoint_option_button.add_item(waypoint_id)
	waypoint_option_button.select(0)
	waypoint_option_button.disabled = true

	var index: int = 0
	var selected_index: int = 0
	for feature: String in ALL_FEATURES:
		feature_option_button.add_item(feature)
		if selected_feature == feature:
			selected_index = index
		index += 1
	feature_option_button.select(selected_index)
	feature_option_button.visible = true

	_set_delete_button()


func set_waypoint_editor_as_editable(connected_waypoints_dictionary: Dictionary[String, String], all_waypoints_ids_array: Array[String]) -> void:
	waypoint_option_button.clear()
	waypoint_option_button.add_item("New Connection...")
	waypoint_option_button.set_item_disabled(0, true)

	var index: int = 1
	for waypoint_id: String in all_waypoints_ids_array.slice(0, 15):
		waypoint_option_button.add_item(waypoint_id)
		if connected_waypoints_dictionary.has(waypoint_id):
			waypoint_option_button.set_item_disabled(index, true)
		index += 1

	waypoint_option_button.select(0)
	_set_new_button()


func _set_new_button() -> void:
	delete_button_active = false
	editor_button.set_as_new_button()


func _set_delete_button() -> void:
	delete_button_active = true
	editor_button.set_as_delete_button()


func _on_editor_button_button_down() -> void:
	if delete_button_active:
		delete_connection.emit(waypoint_option_button.get_item_text(waypoint_option_button.selected))
		queue_free()
	else:
		if waypoint_option_button.selected != 0:
			add_connection.emit(waypoint_option_button.get_item_text(waypoint_option_button.selected))


func _on_feature_option_button_item_selected(index: int) -> void:
	change_feature.emit(waypoint_option_button.get_item_text(waypoint_option_button.selected), feature_option_button.get_item_text(index))
