extends Control

# Signals for outside nodes
signal start_navigation(from_structure: Structure, to_structure: Structure)
signal cancel_navigation

# Signals for internal nodes
signal _show_room_information(room_name: String, lecturers: String, description: String)
signal _show_building_information(building_name: String, building_letter: String, description: String)
signal _set_from_structure(from_structure: Structure)
signal _set_to_structure(to_structure: Structure)

@onready var distance_label: Label = $SearchElementsControl/SearchBarControl/DistanceLabel
@onready var information_popup_elements_control: Control = $InformationPopupElementsControl

# For pathfinding
var current_selected_structure: Structure
var from_structure: Structure
var to_structure: Structure
var currently_navigating: bool = false


func _on_to_search_bar_line_edit_text_changed(_new_text: String) -> void:
	to_structure = null


func _on_from_search_bar_line_edit_text_changed(_new_text: String) -> void:
	from_structure = null


func _on_navigation_button_button_down() -> void:
	if currently_navigating:
		currently_navigating = false
		cancel_navigation.emit()
		distance_label.visible = false
	elif from_structure != null and to_structure != null:
		currently_navigating = true
		start_navigation.emit(from_structure, to_structure)


func _on_camera_3d_select_structure(selected_structure: Structure) -> void:
	_select_structure(selected_structure)


func _select_structure(selected_structure: Structure) -> void:
	current_selected_structure = selected_structure
	if selected_structure is Room:
		var room_structure: Room = selected_structure as Room
		_show_room_information.emit(room_structure.structure_name, room_structure.lectures, room_structure.description)
	elif selected_structure is Building:
		var building_structure: Building = selected_structure as Building
		_show_building_information.emit(building_structure.structure_name, building_structure.building_letter, building_structure.description)


func _on_from_button_button_down() -> void:
	if current_selected_structure != null:
		from_structure = current_selected_structure
		_set_from_structure.emit(from_structure)


func _on_to_button_button_down() -> void:
	if current_selected_structure != null:
		to_structure = current_selected_structure
		_set_to_structure.emit(to_structure)


func _on_admin_check_button_edit_mode_toggled() -> void:
	if not Globals.edit_mode:
		currently_navigating = false
		cancel_navigation.emit()
	visible = not Globals.edit_mode
	information_popup_elements_control.visible = false


func _on_pathfinder_pathfinding_distance(distance: float) -> void:
	distance_label.text = "Distance: " + str(round(distance))
	distance_label.visible = true
