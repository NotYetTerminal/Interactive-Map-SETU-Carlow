extends Control
class_name UserUIRoot

# Signals for outside nodes
signal start_navigation(from_structure: Structure, to_structure: Structure, allow_stairs: bool)
signal cancel_navigation

# Signals for internal nodes
signal _show_room_information(room_name: String, lecturers: String, description: String)
signal _show_building_information(building_name: String, building_letter: String, description: String)
signal _set_from_structure(from_structure: Structure)
signal _set_to_structure(to_structure: Structure)

# Used by SearchPanel
@onready var building_manager: BuildingManager = $"../../BuildingManager"
@onready var room_manager: RoomManager = $"../../RoomManager"

@onready var search_panel: SearchPanel = $SearchPanel
@onready var distance_label: Label = $SearchElementsControl/ThirdHBoxContainer/DistanceLabel
@onready var h_flow_container: HFlowContainer = $SearchElementsControl/ThirdHBoxContainer/HFlowContainer
@onready var stairs_check_button: CheckButton = $SearchElementsControl/ThirdHBoxContainer/HFlowContainer/VBoxContainer/StairsCheckButton
@onready var information_popup_elements_control: Control = $InformationPopupElementsControl

# For pathfinding
var current_selected_structure: Structure
var from_structure: Structure
var to_structure: Structure
var currently_navigating: bool = false


func _ready() -> void:
	search_panel.set_managers(building_manager, room_manager)


func _on_to_search_bar_line_edit_text_changed(new_text: String) -> void:
	if new_text == "":
		to_structure = null
		hide_search_panel()
	else:
		show_search_panel()


func _on_from_search_bar_line_edit_text_changed(new_text: String) -> void:
	if new_text == "":
		from_structure = null
		hide_search_panel()
	else:
		show_search_panel()


func show_search_panel() -> void:
	distance_label.visible = false
	h_flow_container.visible = false
	search_panel.visible = true


func hide_search_panel() -> void:
	distance_label.visible = currently_navigating
	h_flow_container.visible = true
	search_panel.visible = false


func _on_navigation_button_button_down() -> void:
	if currently_navigating:
		currently_navigating = false
		cancel_navigation.emit()
		distance_label.visible = false
		from_structure = null
		to_structure = null
	elif from_structure != null and to_structure != null:
		currently_navigating = true
		start_navigation.emit(from_structure, to_structure, stairs_check_button.button_pressed)


func select_structure(selected_structure: Structure) -> void:
	current_selected_structure = selected_structure
	if selected_structure is Room:
		var room_structure: Room = selected_structure as Room
		_show_room_information.emit(room_structure.structure_name, room_structure.lectures, room_structure.description)
	elif selected_structure is Building:
		var building_structure: Building = selected_structure as Building
		_show_building_information.emit(building_structure.structure_name, building_structure.building_letter, building_structure.description)


func _on_from_button_button_down() -> void:
	if current_selected_structure != null:
		var temp: Structure
		if currently_navigating:
			if to_structure != null:
				temp = to_structure
			_on_navigation_button_button_down()
		
		from_structure = current_selected_structure
		information_popup_elements_control.visible = false
		_set_from_structure.emit(from_structure)
		
		if temp != null:
			current_selected_structure = temp
			_on_to_button_button_down()


func _on_to_button_button_down() -> void:
	if current_selected_structure != null:
		var temp: Structure
		if currently_navigating:
			if from_structure != null:
				temp = from_structure
			_on_navigation_button_button_down()
		
		to_structure = current_selected_structure
		information_popup_elements_control.visible = false
		_set_to_structure.emit(to_structure)
		
		if temp != null:
			current_selected_structure = temp
			_on_from_button_button_down()


func _on_admin_check_button_edit_mode_toggled() -> void:
	if not Globals.edit_mode:
		currently_navigating = false
		cancel_navigation.emit()
		distance_label.visible = false
	visible = not Globals.edit_mode
	information_popup_elements_control.visible = false


func pathfinding_distance(distance: float) -> void:
	distance_label.text = "Distance: " + str(round(distance)) + " meters"
	distance_label.visible = true


func _on_search_panel_set_from_search_structure(structure: Structure) -> void:
	from_structure = structure
	update_search()


func _on_search_panel_set_to_search_structure(structure: Structure) -> void:
	to_structure = structure
	update_search()


func update_search() -> void:
	hide_search_panel()
	_set_from_structure.emit(from_structure)
	_set_to_structure.emit(to_structure)
