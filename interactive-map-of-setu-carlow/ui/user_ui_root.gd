extends Control

# Signals for outside nodes
signal update_level_number(level_number: int)
signal start_navigation(from_structure: Structure, to_structure: Structure)
signal cancel_navigation
signal zoom_in_button
signal zoom_out_button

# Signals for internal nodes
signal _show_room_information(room_name: String, lecturers: String, description: String)
signal _show_building_information(building_name: String, building_letter: String, description: String)
signal _set_from_structure(from_structure: Structure)
signal _set_to_structure(to_structure: Structure)

@onready var level_indicator_label: Label = $ScreenElementsControl/LeftControl/LevelIndicatorLabel

# Used by level indicator label
var level_name_array: Array[String] = ["Ground Floor", "First Floor", "Second Floor"]
var level_number: int = 1

# For pathfinding
var current_selected_structure: Structure
var from_structure: Structure
var to_structure: Structure
var currently_navigating: bool = false


func _on_to_search_bar_line_edit_text_changed(_new_text: String) -> void:
	to_structure = null


func _on_from_search_bar_line_edit_text_changed(_new_text: String) -> void:
	from_structure = null


func _on_level_up_button_button_down() -> void:
	level_number = min(level_number + 1, 3)
	update_level_label()
	update_level_number.emit(level_number)


func _on_level_down_button_button_down() -> void:
	level_number = max(level_number - 1, 1)
	update_level_label()
	update_level_number.emit(level_number)

# Update level indicator label
func update_level_label() -> void:
	level_indicator_label.text = level_name_array[level_number - 1]


func _on_navigation_button_button_down() -> void:
	if currently_navigating:
		currently_navigating = false
		cancel_navigation.emit()
	elif from_structure != null and to_structure != null:
		currently_navigating = true
		start_navigation.emit(from_structure, to_structure)


func _on_zoom_in_button_button_down() -> void:
	zoom_in_button.emit()


func _on_zoom_out_button_button_down() -> void:
	zoom_out_button.emit()


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
	visible = not Globals.edit_mode
