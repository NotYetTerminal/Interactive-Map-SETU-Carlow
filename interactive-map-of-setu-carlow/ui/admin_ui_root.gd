extends Control

signal spawn_specific_structure(parent: Structure, structure_type: Structures)

# Used for distinguishing different structure types
enum Structures { BuildingStruct, RoomStruct, WaypointStruct }

# Pathfinding Elements
@onready var start_waypoint_label: Label = $PathfindingPanel/VBoxContainer/StartWaypointLabel
@onready var start_button: Button = $PathfindingPanel/VBoxContainer/StartButton
@onready var end_waypoint_label: Label = $PathfindingPanel/VBoxContainer/EndWaypointLabel
@onready var target_button: Button = $PathfindingPanel/VBoxContainer/TargetButton
@onready var distance_label: Label = $PathfindingPanel/VBoxContainer/DistanceLabel
@onready var pathfinding_button: Button = $PathfindingPanel/VBoxContainer/PathfindingButton

# Information Elements
@onready var text_edit_v_box_container: VBoxContainer = $InformationPanel/TextEditVBoxContainer
@onready var structure_type_label: Label = $InformationPanel/TextEditVBoxContainer/StructureTypeLabel
@onready var id_line_edit: LineEdit = $InformationPanel/TextEditVBoxContainer/IDVBoxContainer/IDLineEdit
@onready var longitude_line_edit: LineEdit = $InformationPanel/TextEditVBoxContainer/LongitudeVBoxContainer/LongitudeLineEdit
@onready var latitude_line_edit: LineEdit = $InformationPanel/TextEditVBoxContainer/LatitudeVBoxContainer/LatitudeLineEdit

@onready var name_v_box_container: VBoxContainer = $InformationPanel/TextEditVBoxContainer/NameVBoxContainer
@onready var name_line_edit: LineEdit = $InformationPanel/TextEditVBoxContainer/NameVBoxContainer/NameLineEdit
@onready var description_v_box_container: VBoxContainer = $InformationPanel/TextEditVBoxContainer/DescriptionVBoxContainer
@onready var description_text_edit: TextEdit = $InformationPanel/TextEditVBoxContainer/DescriptionVBoxContainer/DescriptionTextEdit
@onready var building_letter_v_box_container: VBoxContainer = $InformationPanel/TextEditVBoxContainer/BuildingLetterVBoxContainer
@onready var building_letter_line_edit: LineEdit = $InformationPanel/TextEditVBoxContainer/BuildingLetterVBoxContainer/BuildingLetterLineEdit
@onready var lecturers_v_box_container: VBoxContainer = $InformationPanel/TextEditVBoxContainer/LecturersVBoxContainer
@onready var lecturers_line_edit: LineEdit = $InformationPanel/TextEditVBoxContainer/LecturersVBoxContainer/LecturersLineEdit
@onready var floor_number_v_box_container: VBoxContainer = $InformationPanel/TextEditVBoxContainer/FloorNumberVBoxContainer
@onready var floor_number_spin_box: SpinBox = $InformationPanel/TextEditVBoxContainer/FloorNumberVBoxContainer/FloorNumberSpinBox
@onready var parent_id_v_box_container: VBoxContainer = $InformationPanel/TextEditVBoxContainer/ParentIDVBoxContainer
@onready var parent_id_line_edit: LineEdit = $InformationPanel/TextEditVBoxContainer/ParentIDVBoxContainer/ParentIDLineEdit
@onready var parent_type_v_box_container: VBoxContainer = $InformationPanel/TextEditVBoxContainer/ParentTypeVBoxContainer
@onready var parent_type_line_edit: LineEdit = $InformationPanel/TextEditVBoxContainer/ParentTypeVBoxContainer/ParentTypeLineEdit
@onready var waypoint_connections_v_box_container: VBoxContainer = $InformationPanel/TextEditVBoxContainer/WaypointConnectionsVBoxContainer
@onready var waypoint_connections_editors_v_box_container: WaypointConnectionsEditorsVBoxContainer = $InformationPanel/TextEditVBoxContainer/WaypointConnectionsVBoxContainer/WaypointConnectionsEditorsVBoxContainer
@onready var waypoints_updated_time_label: Label = $InformationPanel/TextEditVBoxContainer/WaypointsUpdatedTimeLabel
@onready var buildings_updated_time_label: Label = $InformationPanel/TextEditVBoxContainer/BuildingsUpdatedTimeLabel
@onready var rooms_updated_time_label: Label = $InformationPanel/TextEditVBoxContainer/RoomsUpdatedTimeLabel

@onready var save_button: Button = $InformationPanel/TextEditVBoxContainer/SaveButton
@onready var delete_button: Button = $InformationPanel/TextEditVBoxContainer/DeleteButton
@onready var add_button: Button = $InformationPanel/TextEditVBoxContainer/AddButton

# Window panels
@onready var delete_confirmation_panel: Panel = $DeletionConfirmationPanel
@onready var add_structure_panel: Panel = $AddStructurePanel
@onready var building_button: Button = $AddStructurePanel/Panel/VBoxContainer/BuildingButton
@onready var room_button: Button = $AddStructurePanel/Panel/VBoxContainer/RoomButton
@onready var waypoint_button: Button = $AddStructurePanel/Panel/VBoxContainer/WaypointButton

@onready var input_message_panel: Panel = $InputMessagePanel
@onready var input_message_label: Label = $InputMessagePanel/Panel/VBoxContainer/InputMessageLabel

@onready var login_panel: Panel = $LoginPanel
@onready var email_line_edit: LineEdit = $LoginPanel/EmailLineEdit
@onready var password_line_edit: LineEdit = $LoginPanel/PasswordLineEdit

var selected_structure: Structure
var starting_waypoint: Waypoint
var end_waypoint: Waypoint

# Enable or disable buttons
func check_save_and_delete_buttons() -> void:
	save_button.disabled = selected_structure == null or not Globals.edit_mode
	# Delete button not used for Base Map
	delete_button.disabled = selected_structure == null or selected_structure is BaseMap or not Globals.edit_mode
	# Add button not used for Waypoints
	add_button.disabled = selected_structure == null or selected_structure is Waypoint or not Globals.edit_mode

# Change the editable status of all Text Edits
func change_text_edits() -> void:
	for scene: Control in text_edit_v_box_container.get_children():
		if scene is VBoxContainer:
			for inner_scene: Control in scene.get_children():
				if inner_scene is TextEdit:
					(inner_scene as TextEdit).editable = selected_structure != null and Globals.edit_mode
				elif inner_scene is LineEdit and inner_scene != id_line_edit:
					(inner_scene as LineEdit).editable = selected_structure != null and Globals.edit_mode
				elif inner_scene is SpinBox:
					(inner_scene as SpinBox).editable = selected_structure != null and Globals.edit_mode

# Called when a structure is selected
func _select_structure(structure: Structure) -> void:
	# Change last selection colour back
	if selected_structure != null && selected_structure is Waypoint && selected_structure != starting_waypoint && selected_structure != end_waypoint:
		(selected_structure as Waypoint).change_colour(Color.LIGHT_GRAY)
	
	selected_structure = structure
	
	# Set common values
	if selected_structure != null:
		id_line_edit.text = selected_structure.id
		longitude_line_edit.text = str(selected_structure.longitude)
		latitude_line_edit.text = str(selected_structure.latitude)
	else:
		id_line_edit.text = ""
		longitude_line_edit.text = ""
		latitude_line_edit.text = ""
	
	name_v_box_container.visible = false
	description_v_box_container.visible = false
	building_letter_v_box_container.visible = false
	lecturers_v_box_container.visible = false
	floor_number_v_box_container.visible = false
	parent_id_v_box_container.visible = false
	parent_type_v_box_container.visible = false
	waypoint_connections_v_box_container.visible = false
	
	waypoints_updated_time_label.visible = false
	buildings_updated_time_label.visible = false
	rooms_updated_time_label.visible = false
	
	# TODO for now only use Waypoints for pathfinding
	start_button.disabled = true
	target_button.disabled = true
	
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
		if selected_structure != starting_waypoint && selected_structure != end_waypoint:
			(selected_structure as Waypoint).change_colour(Color.BLACK)
		structure_type_label.text = 'Waypoint'
		show_waypoint_details(selected_structure as Waypoint)
		start_button.disabled = false
		target_button.disabled = false

# Called from the camera
func _on_camera_3d_select_structure(structure: Structure) -> void:
	_select_structure(structure)

# Show elements for BaseMap
func show_base_map_details(select_struct: BaseMap) -> void:
	waypoints_updated_time_label.text = 'Waypoints Updated Time: ' + str(select_struct.waypoints_updated_time)
	waypoints_updated_time_label.visible = true
	buildings_updated_time_label.text = 'Buildings Updated Time: ' + str(select_struct.buildings_updated_time)
	buildings_updated_time_label.visible = true

# Show elements for Buildings
func show_building_details(select_struct: Building) -> void:
	name_line_edit.text = select_struct.structure_name
	name_v_box_container.visible = true
	description_text_edit.text = select_struct.description
	description_v_box_container.visible = true
	building_letter_line_edit.text = select_struct.building_letter
	building_letter_v_box_container.visible = true
	waypoints_updated_time_label.text = 'Waypoints Updated Time: ' + str(select_struct.waypoints_updated_time)
	waypoints_updated_time_label.visible = true
	rooms_updated_time_label.text = 'Rooms Updated Time: ' + str(select_struct.rooms_updated_time)
	rooms_updated_time_label.visible = true

# Show elements for Rooms
func show_room_details(select_struct: Room) -> void:
	name_line_edit.text = select_struct.structure_name
	name_v_box_container.visible = true
	description_text_edit.text = select_struct.description
	description_v_box_container.visible = true
	lecturers_line_edit.text = select_struct.lectures
	lecturers_v_box_container.visible = true
	floor_number_spin_box.value = select_struct.floor_number
	floor_number_v_box_container.visible = true
	parent_id_line_edit.text = select_struct.parent_id
	#TODO for now have Parent ID and Type disabled
	#parent_id_v_box_container.visible = true
	waypoints_updated_time_label.text = 'Waypoints Updated Time: ' + str(select_struct.waypoints_updated_time)
	waypoints_updated_time_label.visible = true

# Show elements for Waypoints
func show_waypoint_details(select_struct: Waypoint) -> void:
	floor_number_spin_box.value = select_struct.floor_number
	floor_number_v_box_container.visible = true
	parent_id_line_edit.text = select_struct.parent_id
	#parent_id_v_box_container.visible = true
	parent_type_line_edit.text = select_struct.parent_type
	#parent_type_v_box_container.visible = true
	var all_waypoint_ids: Array[String] = Globals.pathfinder.get_all_waypoints_by_distance(select_struct.id)
	waypoint_connections_editors_v_box_container.save_waypoints_ids(select_struct.waypoint_connections, all_waypoint_ids)
	waypoint_connections_v_box_container.visible = true

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
		details['parent_id'] = (selected_structure as Room).parent_id
		
		details['waypoints_updated_time'] = (selected_structure as Room).waypoints_updated_time
	elif selected_structure is Waypoint:
		details['floor_number'] = int(floor_number_spin_box.value)
		details['parent_id'] = (selected_structure as Waypoint).parent_id
		details['parent_type'] = (selected_structure as Waypoint).parent_type
		details['waypoint_connections'] = waypoint_connections_editors_v_box_container.connected_waypoints_dictionary
	
	selected_structure.update_details(details)

func show_input_message(message: String) -> void:
	input_message_label.text = message
	input_message_panel.visible = true

func _on_start_button_pressed() -> void:
	if selected_structure == null:
		return
	# If previously selected change back colour
	if starting_waypoint != null:
		starting_waypoint.change_colour(Color.LIGHT_GRAY)
	
	starting_waypoint = selected_structure
	start_waypoint_label.text = "Start: " + starting_waypoint.id
	starting_waypoint.change_colour(Color.ROYAL_BLUE)
	
	check_pathfinding_button()

func _on_target_button_pressed() -> void:
	if selected_structure == null:
		return
	# If previously selected change back colour
	if end_waypoint != null:
		end_waypoint.change_colour(Color.LIGHT_GRAY)
	
	end_waypoint = selected_structure
	end_waypoint_label.text = "End: " + end_waypoint.id
	end_waypoint.change_colour(Color.INDIAN_RED)
	
	check_pathfinding_button()

# Enable once both targets are set
func check_pathfinding_button() -> void:
	var both_waypoints_set: bool = starting_waypoint != null and end_waypoint != null
	pathfinding_button.disabled = not both_waypoints_set
	var distance_calculated: String
	if both_waypoints_set:
		# Convert to radians
		var end_lon_radian: float = deg_to_rad(end_waypoint.longitude)
		var end_lat_radian: float = deg_to_rad(end_waypoint.latitude)
		var start_lon_radian: float = deg_to_rad(starting_waypoint.longitude)
		var start_lat_radian: float = deg_to_rad(starting_waypoint.latitude)
		
		# Calculate distance using Pythagoras’ theorem and equi­rectangular projec­tion
		var x_distance: float = (end_lon_radian - start_lon_radian) * cos((start_lat_radian + start_lat_radian) / 2)
		var y_distance: float = end_lat_radian - start_lat_radian
		var distance: float = sqrt(x_distance*x_distance + y_distance*y_distance) * Globals.EARTH_RADIUS
		# Round distance to 2 decimal places
		distance = round(distance * 100) / 100
		distance_calculated = str(distance) + " meters"
	else:
		distance_calculated = ""
	distance_label.text = "Distance: " + distance_calculated


func _on_pathfinding_button_pressed() -> void:
	var _distance: float = Globals.pathfinder.do_pathfinding(starting_waypoint, end_waypoint)


func _on_reset_button_pressed() -> void:
	# Reset start and end Waypoints labels
	if starting_waypoint != null:
		starting_waypoint.change_colour(Color.LIGHT_GRAY)
	starting_waypoint = null
	start_waypoint_label.text = "Start: "
	
	if end_waypoint != null:
		end_waypoint.change_colour(Color.LIGHT_GRAY)
	end_waypoint = null
	end_waypoint_label.text = "End: "
	
	check_pathfinding_button()
	
	# Reset all Waypoints used in last pathfinding
	Globals.pathfinder.reset()

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
		selected_structure.delete_itself()
		delete_confirmation_panel.visible = false
		_select_structure(null)

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
		spawn_specific_structure.emit(selected_structure, Structures.BuildingStruct)


func _on_room_button_pressed() -> void:
	if selected_structure is not Waypoint:
		add_structure_panel.visible = false
		spawn_specific_structure.emit(selected_structure, Structures.RoomStruct)


func _on_waypoint_button_pressed() -> void:
	if selected_structure is not Waypoint:
		add_structure_panel.visible = false
		spawn_specific_structure.emit(selected_structure, Structures.WaypointStruct)

# Close structure select screen
func _on_add_structure_cancel_button_pressed() -> void:
	add_structure_panel.visible = false


func _on_structure_spawner_select_spawned_structure(structure: Structure) -> void:
	_select_structure(structure)


func _on_close_button_pressed() -> void:
	input_message_panel.visible = false

# Activate Admin
func _on_admin_check_button_edit_mode_toggled() -> void:
	visible = Globals.edit_mode
	change_text_edits()
	check_save_and_delete_buttons()


func _on_login_button_button_down() -> void:
	Globals.firebaseConnector.login_with_credentials(email_line_edit.text, password_line_edit.text)


func _on_firebase_connector_admin_logged_in() -> void:
	login_panel.visible = false


func _on_waypoint_connections_editors_v_box_container_add_connection_waypoint_id(_waypoint_id: String) -> void:
	_on_save_button_pressed()


func _on_waypoint_connections_editors_v_box_container_delete_connection_waypoint_id(_waypoint_id: String) -> void:
	_on_save_button_pressed()


func _on_waypoint_connections_editors_v_box_container_update_connection_feature(_waypoint_id: String, _feature: String) -> void:
	_on_save_button_pressed()
