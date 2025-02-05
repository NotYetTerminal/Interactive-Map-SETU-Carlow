extends Control
class_name AttributeEditorControl

signal add_attribute(value_text: String, parent_control: Control)
signal delete_attribute(value_text: String, parent_control: Control)

@onready var option_button: OptionButton = $HBoxContainer/OptionButton
@onready var editor_button: EditorButton = $HBoxContainer/EditorButton

var delete_button_active: bool = false


func set_editor_as_read_only(option_value: String) -> void:
	option_button.add_item(option_value)
	option_button.select(0)
	option_button.disabled = true
	_set_delete_button()


func set_editor_as_editable(all_options: Array[String], disabled_options: Array[String] = []) -> void:
	option_button.add_item("New...")
	option_button.select(0)
	option_button.set_item_disabled(0, true)
	
	var index: int = 1
	for option_value: String in all_options:
		option_button.add_item(option_value)
		if disabled_options.has(option_value):
			option_button.set_item_disabled(index, true)
		index += 1
	
	option_button.disabled = false
	_set_new_button()


func _set_new_button() -> void:
	delete_button_active = false
	editor_button.set_as_new_button()


func _set_delete_button() -> void:
	delete_button_active = true
	editor_button.set_as_delete_button()


func _on_editor_button_button_down() -> void:
	if delete_button_active:
		delete_attribute.emit(option_button.get_item_text(option_button.selected), get_parent())
		queue_free()
	else:
		add_attribute.emit(option_button.get_item_text(option_button.selected), get_parent())
