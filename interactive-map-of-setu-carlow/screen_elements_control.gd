extends Control

# Signals for outside nodes
signal update_floor_number(floor_number: int)
signal zoom_in_button
signal zoom_out_button

@onready var floor_indicator_label: Label = $LeftControl/FloorIndicatorLabel

# Used by floor indicator label
var floor_name_array: Array[String] = ["Ground Floor", "First Floor", "Second Floor"]
var floor_number: int = 1


func _on_floor_up_button_button_down() -> void:
	floor_number = min(floor_number + 1, 3)
	update_floor_label()
	update_floor_number.emit(floor_number)


func _on_floor_down_button_button_down() -> void:
	floor_number = max(floor_number - 1, 1)
	update_floor_label()
	update_floor_number.emit(floor_number)

# Update floor indicator label
func update_floor_label() -> void:
	floor_indicator_label.text = floor_name_array[floor_number - 1]


func _on_zoom_in_button_button_down() -> void:
	zoom_in_button.emit()


func _on_zoom_out_button_button_down() -> void:
	zoom_out_button.emit()


func _on_admin_check_button_edit_mode_toggled() -> void:
	Globals.base_map.update_visibility_by_floor_number(floor_number)
