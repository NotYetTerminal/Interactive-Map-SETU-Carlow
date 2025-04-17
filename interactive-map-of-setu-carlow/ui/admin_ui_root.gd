extends Control
class_name AdminUIRoot

signal spawn_specific_structure(parent: Structure, structure_type: Structures)
signal cancel_login()

# Used for distinguishing different structure types
enum Structures { BuildingStruct, RoomStruct, WaypointStruct }

# Information Elements
@onready var text_edit_v_box_container: VBoxContainer = $InformationPanel/ScrollContainer/TextEditVBoxContainer
@onready var structure_type_label: Label = $InformationPanel/ScrollContainer/TextEditVBoxContainer/StructureTypeLabel
@onready var id_line_edit: LineEdit = $InformationPanel/ScrollContainer/TextEditVBoxContainer/IDHBoxContainer/IDLineEdit
@onready var longitude_line_edit: LineEdit = $InformationPanel/ScrollContainer/TextEditVBoxContainer/LocationHBoxContainer/LongitudeVBoxContainer/LongitudeLineEdit
@onready var latitude_line_edit: LineEdit = $InformationPanel/ScrollContainer/TextEditVBoxContainer/LocationHBoxContainer/LatitudeVBoxContainer/LatitudeLineEdit
@onready var move_button: Button = $InformationPanel/ScrollContainer/TextEditVBoxContainer/LocationHBoxContainer/MoveButton

@onready var name_h_box_container: HBoxContainer = $InformationPanel/ScrollContainer/TextEditVBoxContainer/NameHBoxContainer
@onready var name_line_edit: LineEdit = $InformationPanel/ScrollContainer/TextEditVBoxContainer/NameHBoxContainer/NameLineEdit
@onready var description_v_box_container: VBoxContainer = $InformationPanel/ScrollContainer/TextEditVBoxContainer/DescriptionVBoxContainer
@onready var description_text_edit: TextEdit = $InformationPanel/ScrollContainer/TextEditVBoxContainer/DescriptionVBoxContainer/HBoxContainer/VBoxContainer/DescriptionTextEdit
@onready var building_letter_h_box_container: HBoxContainer = $InformationPanel/ScrollContainer/TextEditVBoxContainer/BuildingLetterHBoxContainer
@onready var building_letter_line_edit: LineEdit = $InformationPanel/ScrollContainer/TextEditVBoxContainer/BuildingLetterHBoxContainer/BuildingLetterLineEdit
@onready var lecturers_h_box_container: HBoxContainer = $InformationPanel/ScrollContainer/TextEditVBoxContainer/LecturersHBoxContainer
@onready var lecturers_line_edit: LineEdit = $InformationPanel/ScrollContainer/TextEditVBoxContainer/LecturersHBoxContainer/LecturersLineEdit
@onready var floor_number_h_box_container: HBoxContainer = $InformationPanel/ScrollContainer/TextEditVBoxContainer/FloorNumberHBoxContainer
@onready var floor_number_spin_box: SpinBox = $InformationPanel/ScrollContainer/TextEditVBoxContainer/FloorNumberHBoxContainer/FloorNumberSpinBox
@onready var parent_h_box_container: HBoxContainer = $InformationPanel/ScrollContainer/TextEditVBoxContainer/ParentHBoxContainer
@onready var parent_line_edit: LineEdit = $InformationPanel/ScrollContainer/TextEditVBoxContainer/ParentHBoxContainer/ParenLineEdit
@onready var waypoint_connections_scroll_container: ScrollContainer = $InformationPanel/ScrollContainer/TextEditVBoxContainer/WaypointConnectionsScrollContainer
@onready var waypoint_connections_editors_v_box_container: WaypointConnectionsEditorsVBoxContainer = $InformationPanel/ScrollContainer/TextEditVBoxContainer/WaypointConnectionsScrollContainer/WaypointConnectionsVBoxContainer/WaypointConnectionsEditorsVBoxContainer
@onready var waypoints_updated_time_label: Label = $InformationPanel/ScrollContainer/TextEditVBoxContainer/TimeHBoxContainer/WaypointsUpdatedTimeLabel
@onready var buildings_updated_time_label: Label = $InformationPanel/ScrollContainer/TextEditVBoxContainer/TimeHBoxContainer2/BuildingsUpdatedTimeLabel
@onready var rooms_updated_time_label: Label = $InformationPanel/ScrollContainer/TextEditVBoxContainer/TimeHBoxContainer3/RoomsUpdatedTimeLabel

@onready var button_pusher_control: Control = $InformationPanel/ScrollContainer/TextEditVBoxContainer/ButtonPusherControl
@onready var save_button: Button = $InformationPanel/ScrollContainer/TextEditVBoxContainer/ButtonsHBoxContainer/SaveButton
@onready var delete_button: Button = $InformationPanel/ScrollContainer/TextEditVBoxContainer/ButtonsHBoxContainer/DeleteButton
@onready var add_button: Button = $InformationPanel/ScrollContainer/TextEditVBoxContainer/ButtonsHBoxContainer/AddButton

# Window panels
@onready var delete_confirmation_panel: Panel = $DeletionConfirmationPanel
@onready var add_structure_panel: Panel = $AddStructurePanel
@onready var building_button: Button = $AddStructurePanel/Panel/VBoxContainer/BuildingButton
@onready var room_button: Button = $AddStructurePanel/Panel/VBoxContainer/RoomButton
@onready var waypoint_button: Button = $AddStructurePanel/Panel/VBoxContainer/WaypointButton

@onready var input_message_panel: Panel = $InputMessagePanel
@onready var input_message_label: Label = $InputMessagePanel/Panel/VBoxContainer/InputMessageLabel
@onready var input_message_close_button: Button = $InputMessagePanel/Panel/VBoxContainer/CloseButton

@onready var login_panel: Panel = $LoginPanel
@onready var email_line_edit: LineEdit = $LoginPanel/EmailLineEdit
@onready var password_line_edit: LineEdit = $LoginPanel/PasswordLineEdit

var selected_structure: Structure
var spawning_structure: bool = false


func _input(event: InputEvent) -> void:
	if selected_structure != null and selected_structure.mouse_editing and event is InputEventMouseMotion:
		longitude_line_edit.text = str(selected_structure.longitude)
		latitude_line_edit.text = str(selected_structure.latitude)

# Enable or disable buttons
func check_save_and_delete_buttons() -> void:
	save_button.disabled = selected_structure == null or (selected_structure != null and selected_structure.mouse_editing)
	# Delete button not used for Base Map
	delete_button.disabled = selected_structure == null or selected_structure is BaseMap or (selected_structure != null and selected_structure.mouse_editing)
	# Add button not used for Waypoints
	add_button.disabled = selected_structure == null or selected_structure is Waypoint or (selected_structure != null and (selected_structure.mouse_editing or not selected_structure.saved))
	move_button.disabled = selected_structure == null or (selected_structure != null and selected_structure.mouse_editing)

# Change the editable status of all Text Edits
func change_text_edits() -> void:
	for scene: Control in text_edit_v_box_container.get_children():
		if scene is VBoxContainer or scene is HBoxContainer:
			for inner_scene: Control in scene.get_children():
				if inner_scene is TextEdit:
					(inner_scene as TextEdit).editable = selected_structure != null and Globals.edit_mode
				elif inner_scene is LineEdit and inner_scene != id_line_edit and inner_scene != parent_line_edit:
					(inner_scene as LineEdit).editable = selected_structure != null and Globals.edit_mode
				elif inner_scene is SpinBox:
					(inner_scene as SpinBox).editable = selected_structure != null and Globals.edit_mode
				# For the LocationHBoxContainer
				elif inner_scene is VBoxContainer:
					for inner_scene2: Control in inner_scene.get_children():
						if inner_scene2 is LineEdit:
							(inner_scene2 as LineEdit).editable = selected_structure != null and Globals.edit_mode

# Called when a structure is selected
func select_structure(structure: Structure) -> void:
	# Change last selection colour back
	if selected_structure != null && selected_structure is Waypoint:
		(selected_structure as Waypoint).change_colour(Color.LIGHT_GRAY)

	selected_structure = structure

	# Set common values
	if selected_structure != null:
		id_line_edit.text = selected_structure.id
		longitude_line_edit.text = str(selected_structure.longitude)
		latitude_line_edit.text = str(selected_structure.latitude)
		if selected_structure.just_moved:
			selected_structure.just_moved = false
			_on_save_button_pressed()
			spawning_structure = false
	else:
		id_line_edit.text = ""
		longitude_line_edit.text = ""
		latitude_line_edit.text = ""

	name_h_box_container.visible = false
	description_v_box_container.visible = false
	building_letter_h_box_container.visible = false
	lecturers_h_box_container.visible = false
	floor_number_h_box_container.visible = false
	parent_h_box_container.visible = false
	waypoint_connections_scroll_container.visible = false

	button_pusher_control.visible = true
	waypoints_updated_time_label.visible = false
	buildings_updated_time_label.visible = false
	rooms_updated_time_label.visible = false

	change_text_edits()
	check_save_and_delete_buttons()

	# Set individual ones
	if selected_structure is BaseMap:
		structure_type_label.text = 'Base Map'
		show_base_map_details(selected_structure as BaseMap)
	elif selected_structure is Building:
		structure_type_label.text = 'Building'
		show_building_details(selected_structure as Building)
	elif selected_structure is Room:
		structure_type_label.text = 'Room'
		show_room_details(selected_structure as Room)
	elif selected_structure is Waypoint:
		(selected_structure as Waypoint).change_colour(Color.BLACK)
		structure_type_label.text = 'Waypoint'
		show_waypoint_details(selected_structure as Waypoint)

# Show elements for BaseMap
func show_base_map_details(select_struct: BaseMap) -> void:
	waypoints_updated_time_label.text = 'Waypoints Updated Time: ' + Time.get_datetime_string_from_unix_time(select_struct.waypoints_updated_time, true)
	waypoints_updated_time_label.visible = true
	buildings_updated_time_label.text = 'Buildings Updated Time: ' + Time.get_datetime_string_from_unix_time(select_struct.buildings_updated_time, true)
	buildings_updated_time_label.visible = true
	button_pusher_control.visible = true

# Show elements for Buildings
func show_building_details(select_struct: Building) -> void:
	name_line_edit.text = select_struct.structure_name
	name_h_box_container.visible = true
	description_text_edit.text = select_struct.description
	description_v_box_container.visible = true
	building_letter_line_edit.text = select_struct.building_letter
	building_letter_h_box_container.visible = true
	waypoints_updated_time_label.text = 'Waypoints Updated Time: ' + Time.get_datetime_string_from_unix_time(select_struct.waypoints_updated_time, true)
	waypoints_updated_time_label.visible = true
	rooms_updated_time_label.text = 'Rooms Updated Time: ' + Time.get_datetime_string_from_unix_time(select_struct.rooms_updated_time, true)
	rooms_updated_time_label.visible = true
	button_pusher_control.visible = true

# Show elements for Rooms
func show_room_details(select_struct: Room) -> void:
	name_line_edit.text = select_struct.structure_name
	name_h_box_container.visible = true
	description_text_edit.text = select_struct.description
	description_v_box_container.visible = true
	lecturers_line_edit.text = select_struct.lectures
	lecturers_h_box_container.visible = true
	floor_number_spin_box.value = select_struct.floor_number
	floor_number_h_box_container.visible = true
	parent_line_edit.text = select_struct.get_parent_structure().structure_name
	parent_h_box_container.visible = true
	waypoints_updated_time_label.text = 'Waypoints Updated Time: ' + Time.get_datetime_string_from_unix_time(select_struct.waypoints_updated_time, true)
	waypoints_updated_time_label.visible = true
	button_pusher_control.visible = true

# Show elements for Waypoints
func show_waypoint_details(select_struct: Waypoint) -> void:
	floor_number_spin_box.value = select_struct.floor_number
	floor_number_h_box_container.visible = true
	parent_line_edit.text = select_struct.get_parent_structure().structure_name
	parent_h_box_container.visible = true
	var all_waypoint_ids: Array[String] = Globals.pathfinder.get_all_waypoints_by_distance(select_struct.id)
	waypoint_connections_editors_v_box_container.save_waypoints_ids(select_struct.waypoint_connections, all_waypoint_ids)
	waypoint_connections_scroll_container.visible = true
	button_pusher_control.visible = false

# Save variables on Save button press
func _on_save_button_pressed() -> void:
	if selected_structure == null:
		return

	var longitude_value: float = longitude_line_edit.text.to_float()
	var latitude_value: float = latitude_line_edit.text.to_float()
	if longitude_value < -6.938 or longitude_value > -6.931:
		show_input_message("Longitude must be between -6.938 and -6.931")
		return
	elif latitude_value < 52.822 or latitude_value > 52.83:
		show_input_message("Latitude must be between 52.822 and 52.83")
		return

	# Common values
	var details: Dictionary = {
		'longitude': longitude_value,
		'latitude': latitude_value
	}
	if selected_structure is BaseMap:
		details['waypoints_updated_time'] = (selected_structure as BaseMap).waypoints_updated_time
		details['buildings_updated_time'] = (selected_structure as BaseMap).buildings_updated_time
	elif selected_structure is Building:
		if name_line_edit.text == "":
			show_input_message("Name must not be empty.")
			return
		elif description_text_edit.text == "":
			show_input_message("Description must not be empty.")
			return
		elif building_letter_line_edit.text == "":
			show_input_message("Building Letter must not be empty.")
			return

		details['name'] = name_line_edit.text
		details['description'] = description_text_edit.text
		details['building_letter'] = building_letter_line_edit.text

		details['waypoints_updated_time'] = (selected_structure as Building).waypoints_updated_time
		details['rooms_updated_time'] = (selected_structure as Building).rooms_updated_time
	elif selected_structure is Room:
		if name_line_edit.text == "":
			show_input_message("Name must not be empty.")
			return
		elif description_text_edit.text == "":
			show_input_message("Description must not be empty.")
			return

		details['name'] = name_line_edit.text
		details['description'] = description_text_edit.text
		details['lecturers'] = lecturers_line_edit.text
		details['floor_number'] = int(floor_number_spin_box.value)

		details['waypoints_updated_time'] = (selected_structure as Room).waypoints_updated_time
	elif selected_structure is Waypoint:
		details['floor_number'] = int(floor_number_spin_box.value)
		var waypoint_dictionary: Dictionary[String, String] = {}
		for waypoint_id: String in waypoint_connections_editors_v_box_container.connected_waypoints_dictionary.keys():
			waypoint_dictionary[waypoint_id] = waypoint_connections_editors_v_box_container.connected_waypoints_dictionary[waypoint_id]
		details['waypoint_connections'] = waypoint_dictionary

	show_input_message_mid_action("Saving")
	@warning_ignore("redundant_await")
	await selected_structure.update_details(details)
	if selected_structure != null:
		selected_structure.update_visibility()
	check_save_and_delete_buttons()
	close_input_message_finished_action()


func show_input_message(message: String) -> void:
	if not spawning_structure:
		input_message_label.text = message
		input_message_panel.visible = true
		input_message_close_button.visible = true


func show_input_message_mid_action(message: String) -> void:
	show_input_message(message)
	input_message_close_button.visible = false


func close_input_message_finished_action() -> void:
	input_message_panel.visible = false

# Used to delete a structure
func _on_delete_button_pressed() -> void:
	if selected_structure is not BaseMap:
		delete_confirmation_panel.visible = true

# Close confirmation window
func _on_delete_cancel_button_pressed() -> void:
	delete_confirmation_panel.visible = false

# Delete structure selected
func _on_confirm_button_pressed() -> void:
	if selected_structure is not BaseMap:
		show_input_message_mid_action("Deleting")
		delete_confirmation_panel.visible = false
		@warning_ignore("redundant_await")
		await selected_structure.delete_itself()
		close_input_message_finished_action()
		select_structure(null)

# Open up choosing window
func _on_add_button_pressed() -> void:
	if selected_structure is not Waypoint:
		building_button.visible = false
		room_button.visible = false
		if selected_structure is BaseMap:
			building_button.visible = true
		elif selected_structure is Building:
			room_button.visible = true
		add_structure_panel.visible = true

# Spawn the structure selected
func _on_building_button_pressed() -> void:
	if selected_structure is not Waypoint:
		add_structure_panel.visible = false
		spawning_structure = true
		spawn_specific_structure.emit(selected_structure, Structures.BuildingStruct)


func _on_room_button_pressed() -> void:
	if selected_structure is not Waypoint:
		add_structure_panel.visible = false
		spawning_structure = true
		spawn_specific_structure.emit(selected_structure, Structures.RoomStruct)


func _on_waypoint_button_pressed() -> void:
	if selected_structure is not Waypoint:
		add_structure_panel.visible = false
		spawning_structure = true
		spawn_specific_structure.emit(selected_structure, Structures.WaypointStruct)

# Close structure select screen
func _on_add_structure_cancel_button_pressed() -> void:
	add_structure_panel.visible = false


func _on_close_button_pressed() -> void:
	input_message_panel.visible = false

# Activate Admin
func _on_admin_check_button_edit_mode_toggled() -> void:
	visible = Globals.edit_mode
	change_text_edits()
	check_save_and_delete_buttons()


func _on_login_button_button_down() -> void:
	Globals.firebaseConnector.login_with_credentials(email_line_edit.text, password_line_edit.text)


func admin_logged_in() -> void:
	login_panel.visible = false


func _on_waypoint_connections_editors_v_box_container_add_connection_waypoint_id(_waypoint_id: String) -> void:
	_on_save_button_pressed()


func _on_waypoint_connections_editors_v_box_container_delete_connection_waypoint_id(_waypoint_id: String) -> void:
	_on_save_button_pressed()


func _on_waypoint_connections_editors_v_box_container_update_connection_feature(_waypoint_id: String, _feature: String) -> void:
	_on_save_button_pressed()


func _on_cancel_button_button_down() -> void:
	cancel_login.emit()


func _on_move_button_button_up() -> void:
	print("MOVE")
	if selected_structure != null:
		selected_structure.mouse_editing = true
		check_save_and_delete_buttons()
