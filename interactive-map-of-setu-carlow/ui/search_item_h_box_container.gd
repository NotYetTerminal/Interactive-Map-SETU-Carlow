extends HBoxContainer
class_name SearchItemHBoxContainer

signal from_button_pressed(struct: Structure)
signal to_button_pressed(struct: Structure)
signal bookmark_button_pressed(this_container: SearchItemHBoxContainer)

@onready var name_label: Label = $ScrollContainer/VBoxContainer/NameLabel
@onready var location_label: Label = $ScrollContainer/VBoxContainer/LocationLabel
@onready var extra_information_label: Label = $ScrollContainer/VBoxContainer/ExtraInformationLabel
@onready var bookmark_button: EditorButton = $HBoxContainer/AspectRatioContainer/BookmarkButton

var structure: Structure


func set_details(struct: Structure, structure_name: String, location_text: String, extra_information: String) -> void:
	structure = struct
	name_label.text = structure_name
	location_label.text = location_text
	extra_information_label.text = extra_information


func set_bookmark_button(add: bool) -> void:
	if add:
		bookmark_button.set_as_new_button()
	else:
		bookmark_button.set_as_delete_button()


func _on_from_button_button_down() -> void:
	from_button_pressed.emit(structure)


func _on_to_button_button_down() -> void:
	to_button_pressed.emit(structure)


func _on_bookmark_button_button_down() -> void:
	bookmark_button_pressed.emit(self)
