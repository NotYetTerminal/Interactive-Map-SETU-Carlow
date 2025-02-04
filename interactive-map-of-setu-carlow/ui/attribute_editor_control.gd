extends Control

signal attribute_button_down(delete_button_active: bool, value_text: String)

@onready var line_edit: LineEdit = $HBoxContainer/LineEdit
@onready var option_button: OptionButton = $HBoxContainer/OptionButton
@onready var editor_button: EditorButton = $HBoxContainer/EditorButton

@export var line_edit_active: bool = true
var delete_button_active: bool = false


func _ready() -> void:
	if line_edit_active:
		set_editor_as_line_edit()
	else:
		set_editor_as_dropdown([])


func set_editor_as_line_edit() -> void:
	line_edit_active = true
	line_edit.visible = true
	option_button.visible = false


func set_editor_as_dropdown(waypoint_ids_array: Array[String]) -> void:
	for waypoint_id: String in waypoint_ids_array:
		option_button.add_item(waypoint_id)
	line_edit_active = false
	line_edit.visible = false
	option_button.visible = true


func set_new_button() -> void:
	delete_button_active = false
	editor_button.set_as_new_button()


func set_delete_button() -> void:
	delete_button_active = true
	editor_button.set_as_delete_button()


func _on_editor_button_button_down() -> void:
	if line_edit_active:
		attribute_button_down.emit(delete_button_active, line_edit.text)
	else:
		attribute_button_down.emit(delete_button_active, option_button.get_item_text(option_button.selected))
	
	if delete_button_active:
		queue_free()
