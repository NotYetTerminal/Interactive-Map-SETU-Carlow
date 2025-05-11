extends Control
class_name UserUIRoot

# Signals for outside nodes
signal start_navigation(from_structure: Structure, to_structure: Structure, allow_stairs: bool)
signal cancel_navigation
signal snap_to_structure(structure: Structure)

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
@onready var third_h_box_container: HBoxContainer = $SearchElementsControl/ThirdHBoxContainer
@onready var stairs_check_button: CheckButton = $SearchElementsControl/ThirdHBoxContainer/HFlowContainer/VBoxContainer/StairsCheckButton
@onready var information_popup_elements_control: Control = $InformationPopupElementsControl

# For pathfinding
var current_selected_structure: Structure
var from_structure: Structure
var to_structure: Structure
var currently_navigating: bool = false
var previous_from_structure: Structure
var previous_to_structure: Structure


func _ready() -> void:
	search_panel.set_managers(building_manager, room_manager)


func _on_to_search_bar_line_edit_text_changed(new_text: String) -> void:
	if new_text == "":
		if to_structure != null:
			to_structure.set_mesh_colour()
		to_structure = null
		hide_search_panel()
		if from_structure == null:
			clear_navigation()
			unset_previous()
	else:
		show_search_panel()


func _on_from_search_bar_line_edit_text_changed(new_text: String) -> void:
	if new_text == "":
		if from_structure != null:
			from_structure.set_mesh_colour()
		from_structure = null
		hide_search_panel()
		if to_structure == null:
			clear_navigation()
			unset_previous()
	else:
		show_search_panel()


func unset_previous() -> void:
	if previous_from_structure != null:
		previous_from_structure.set_mesh_colour()
	if previous_to_structure != null:
		previous_to_structure.set_mesh_colour()
	previous_from_structure = null
	previous_to_structure = null


func show_search_panel() -> void:
	third_h_box_container.visible = false
	search_panel.visible = true


func hide_search_panel() -> void:
	distance_label.visible = currently_navigating
	third_h_box_container.visible = true
	search_panel.visible = false


func _on_navigation_button_button_down(stairs_changed: bool = false) -> void:
	if from_structure != null and to_structure != null and (
		previous_from_structure != from_structure or previous_to_structure != to_structure or stairs_changed
	):
		if previous_from_structure != null:
			previous_from_structure.set_mesh_colour()
		if previous_to_structure != null:
			previous_to_structure.set_mesh_colour()
		from_structure.set_mesh_colour(Color.LAWN_GREEN)
		to_structure.set_mesh_colour(Color.RED)
		currently_navigating = true
		save_pathfinding_structures()
		start_navigation.emit(from_structure, to_structure, stairs_check_button.button_pressed)
		previous_from_structure = from_structure
		previous_to_structure = to_structure


func clear_navigation() -> void:
	if from_structure != null:
		from_structure.set_mesh_colour()
	if to_structure != null:
		to_structure.set_mesh_colour()
	currently_navigating = false
	cancel_navigation.emit()
	distance_label.visible = false
	from_structure = null
	to_structure = null
	save_pathfinding_structures()


func select_structure(selected_structure: Structure) -> void:
	current_selected_structure = selected_structure
	if selected_structure is Room:
		var room_structure: Room = selected_structure as Room
		_show_room_information.emit(room_structure.structure_name, room_structure.lectures, room_structure.description)
	elif selected_structure is Building:
		var building_structure: Building = selected_structure as Building
		_show_building_information.emit(building_structure.structure_name, building_structure.building_letter, building_structure.description)


func _on_from_button_button_down(call_other: bool = true) -> void:
	if current_selected_structure != null:
		var temp: Structure
		if currently_navigating:
			if to_structure != null:
				temp = to_structure
			_on_navigation_button_button_down()

		if from_structure != null:
			from_structure.set_mesh_colour()
		from_structure = current_selected_structure
		from_structure.set_mesh_colour(Color.LAWN_GREEN)
		information_popup_elements_control.visible = false
		_set_from_structure.emit(from_structure)

		if temp != null and call_other:
			current_selected_structure = temp
			_on_to_button_button_down(false)


func _on_to_button_button_down(call_other: bool = true) -> void:
	if current_selected_structure != null:
		var temp: Structure
		if currently_navigating:
			if from_structure != null:
				temp = from_structure
			_on_navigation_button_button_down()

		if to_structure != null:
			to_structure.set_mesh_colour()
		to_structure = current_selected_structure
		to_structure.set_mesh_colour(Color.RED)
		information_popup_elements_control.visible = false
		_set_to_structure.emit(to_structure)

		if temp != null and call_other:
			current_selected_structure = temp
			_on_from_button_button_down(false)


func _on_admin_check_button_edit_mode_toggled() -> void:
	if not Globals.edit_mode:
		clear_navigation()
	visible = not Globals.edit_mode
	information_popup_elements_control.visible = false


func pathfinding_distance(distance: float) -> void:
	distance_label.text = "Distance: " + str(round(distance)) + " meters"
	distance_label.visible = true


func _on_search_panel_set_from_search_structure(structure: Structure) -> void:
	if from_structure != null:
		from_structure.set_mesh_colour()
	from_structure = structure
	from_structure.set_mesh_colour(Color.LAWN_GREEN)
	update_search()


func _on_search_panel_set_to_search_structure(structure: Structure) -> void:
	if to_structure != null:
		to_structure.set_mesh_colour()
	to_structure = structure
	to_structure.set_mesh_colour(Color.RED)
	update_search()


func update_search() -> void:
	hide_search_panel()
	_set_from_structure.emit(from_structure)
	_set_to_structure.emit(to_structure)


func load_bookmarks() -> void:
	search_panel.load_bookmarks()


func load_pathfinding_structures() -> void:
	var file: FileAccess = FileAccess.open("user://pathfinding_structures", FileAccess.READ)
	if file != null and file.get_length() != 0:
		var pathfinding_structures: Dictionary = file.get_var()
		if len(pathfinding_structures.keys()) != 0:
			var structure_id: String = pathfinding_structures["from_structure_id"]
			from_structure = building_manager.get_building(structure_id)
			if from_structure == null:
				from_structure = room_manager.get_room(structure_id)

			structure_id = pathfinding_structures["to_structure_id"]
			to_structure = building_manager.get_building(structure_id)
			if to_structure == null:
				to_structure = room_manager.get_room(structure_id)

			from_structure.set_mesh_colour(Color.LAWN_GREEN)
			to_structure.set_mesh_colour(Color.RED)
			stairs_check_button.button_pressed = pathfinding_structures["stairs"]

			update_search()
			_on_navigation_button_button_down()


func save_pathfinding_structures() -> void:
	var file: FileAccess = FileAccess.open("user://pathfinding_structures", FileAccess.WRITE)
	if file != null:
		var pathfinding_structures: Dictionary = {}
		if currently_navigating:
			pathfinding_structures["from_structure_id"] = from_structure.id
			pathfinding_structures["to_structure_id"] = to_structure.id
			pathfinding_structures["stairs"] = stairs_check_button.button_pressed
		var _error: bool = file.store_var(pathfinding_structures)


func _on_stairs_check_button_pressed() -> void:
	_on_navigation_button_button_down(true)


func _on_search_panel_snap_to_structure(structure: Structure) -> void:
	hide_search_panel()
	snap_to_structure.emit(structure)
