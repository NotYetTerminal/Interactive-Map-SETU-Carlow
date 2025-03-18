extends Control

# Signals for outside nodes
signal update_floor_number()

@onready var floor_indicator_label: Label = $LeftControl/AspectRatioContainer3/FloorIndicatorLabel

# Used by floor indicator label
var floor_name_array: Array[String] = ["Ground Floor", "First Floor", "Second Floor"]
var floor_number: int = 1


func _on_floor_up_button_button_down() -> void:
	floor_number = min(floor_number + 1, 3)
	update_floor_label()
	Globals.current_floor = floor_number
	update_floor_number.emit()


func _on_floor_down_button_button_down() -> void:
	floor_number = max(floor_number - 1, 1)
	update_floor_label()
	Globals.current_floor = floor_number
	update_floor_number.emit()

# Update floor indicator label
func update_floor_label() -> void:
	floor_indicator_label.text = floor_name_array[floor_number - 1]
