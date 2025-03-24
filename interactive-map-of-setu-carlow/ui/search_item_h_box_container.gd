extends HBoxContainer
class_name SearchItemHBoxContainer

signal from_button_pressed(struct: Structure)
signal to_button_pressed(struct: Structure)

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var location_label: Label = $VBoxContainer/LocationLabel
@onready var extra_information_label: Label = $VBoxContainer/ExtraInformationLabel

var structure: Structure


func set_details(struct: Structure, structure_name: String, location_text: String, extra_information: String) -> void:
	structure = struct
	name_label.text = structure_name
	location_label.text = location_text
	if extra_information.to_lower() == "none":
		extra_information_label.text = ""
	else:
		extra_information_label.text = extra_information


func _on_from_button_button_down() -> void:
	from_button_pressed.emit(structure)


func _on_to_button_button_down() -> void:
	to_button_pressed.emit(structure)
