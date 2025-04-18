extends Control

@onready var information_popup_control: Control = $InformationPopupPanel
@onready var name_label: Label = $InformationPopupPanel/InformationScrollContainer/InformationPopupVBoxContainer/NameLabel
@onready var lecturers_label: Label = $InformationPopupPanel/InformationScrollContainer/InformationPopupVBoxContainer/LecturersLabel
@onready var building_letter_label: Label = $InformationPopupPanel/InformationScrollContainer/InformationPopupVBoxContainer/BuildingLetterLabel
@onready var description_label: Label = $InformationPopupPanel/InformationScrollContainer/InformationPopupVBoxContainer/DescriptionLabel
@onready var aspect_ratio_container: AspectRatioContainer = $AspectRatioContainer
@onready var aspect_ratio_container_2: AspectRatioContainer = $AspectRatioContainer2


func _ready() -> void:
	var os_name: String = OS.get_name()
	if os_name == "Android" or (os_name == "Web" and OS.has_feature("web_android")):
		information_popup_control.anchor_top = 0.4
		information_popup_control.anchor_bottom = 0.6
		aspect_ratio_container.anchor_top = 0.55
		aspect_ratio_container.anchor_bottom = 0.65
		aspect_ratio_container_2.anchor_top = 0.55
		aspect_ratio_container_2.anchor_bottom = 0.65


func show_room_information(room_name: String, lecturers: String, description: String) -> void:
	name_label.text = room_name
	if lecturers.to_lower() != "none":
		lecturers_label.text = "Lecturers: " + lecturers
		lecturers_label.visible = true
	else:
		lecturers_label.visible = false
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
