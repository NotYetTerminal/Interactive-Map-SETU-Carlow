extends Control

@onready var name_label: Label = $InformationPopupControl/InformationScrollContainer/InformationPopupVBoxContainer/NameLabel
@onready var lecturers_label: Label = $InformationPopupControl/InformationScrollContainer/InformationPopupVBoxContainer/LecturersLabel
@onready var building_letter_label: Label = $InformationPopupControl/InformationScrollContainer/InformationPopupVBoxContainer/BuildingLetterLabel
@onready var description_label: Label = $InformationPopupControl/InformationScrollContainer/InformationPopupVBoxContainer/DescriptionLabel


func show_room_information(room_name: String, lecturers: String, description: String) -> void:
	name_label.text = room_name
	lecturers_label.text = "Lecturers: " + lecturers
	lecturers_label.visible = true
	building_letter_label.visible = false
	description_label.text = description
	visible = true


func show_building_information(building_name: String, building_letter: String, description: String) -> void:
	name_label.text = building_name
	lecturers_label.visible = false
	building_letter_label.text = "Building Letter: " + building_letter
	building_letter_label.visible = true
	description_label.text = description
	visible = true


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var input_event: InputEventMouseButton = event as InputEventMouseButton
		if (input_event.button_index == MOUSE_BUTTON_LEFT or input_event.button_index == MOUSE_BUTTON_RIGHT) and input_event.is_pressed():
			visible = false
