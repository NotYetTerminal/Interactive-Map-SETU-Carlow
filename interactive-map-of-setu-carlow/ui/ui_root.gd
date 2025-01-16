extends Control

signal edit_mode_toggled
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
@onready var id_label: Label = $InformationPanel/TextEditVBoxContainer/IDLabel
@onready var longitude_text_edit: TextEdit = $InformationPanel/TextEditVBoxContainer/LongitudeVBoxContainer/LongitudeTextEdit
@onready var latitude_text_edit: TextEdit = $InformationPanel/TextEditVBoxContainer/LatitudeVBoxContainer/LatitudeTextEdit

@onready var name_v_box_container: VBoxContainer = $InformationPanel/TextEditVBoxContainer/NameVBoxContainer
@onready var name_text_edit: TextEdit = $InformationPanel/TextEditVBoxContainer/NameVBoxContainer/NameTextEdit
@onready var description_v_box_container: VBoxContainer = $InformationPanel/TextEditVBoxContainer/DescriptionVBoxContainer
@onready var description_text_edit: TextEdit = $InformationPanel/TextEditVBoxContainer/DescriptionVBoxContainer/DescriptionTextEdit
@onready var building_letter_v_box_container: VBoxContainer = $InformationPanel/TextEditVBoxContainer/BuildingLetterVBoxContainer
@onready var building_letter_text_edit: TextEdit = $InformationPanel/TextEditVBoxContainer/BuildingLetterVBoxContainer/BuildingLetterTextEdit
@onready var lecturers_v_box_container: VBoxContainer = $InformationPanel/TextEditVBoxContainer/LecturersVBoxContainer
@onready var lecturers_text_edit: TextEdit = $InformationPanel/TextEditVBoxContainer/LecturersVBoxContainer/LecturersTextEdit
@onready var floor_number_v_box_container: VBoxContainer = $InformationPanel/TextEditVBoxContainer/FloorNumberVBoxContainer
@onready var floor_number_text_edit: TextEdit = $InformationPanel/TextEditVBoxContainer/FloorNumberVBoxContainer/FloorNumberTextEdit
@onready var feature_type_v_box_container: VBoxContainer = $InformationPanel/TextEditVBoxContainer/FeatureTypeVBoxContainer
@onready var feature_type_text_edit: TextEdit = $InformationPanel/TextEditVBoxContainer/FeatureTypeVBoxContainer/FeatureTypeTextEdit
@onready var parent_id_v_box_container: VBoxContainer = $InformationPanel/TextEditVBoxContainer/ParentIDVBoxContainer
@onready var parent_id_text_edit: TextEdit = $InformationPanel/TextEditVBoxContainer/ParentIDVBoxContainer/ParentIDTextEdit
@onready var parent_type_v_box_container: VBoxContainer = $InformationPanel/TextEditVBoxContainer/ParentTypeVBoxContainer
@onready var parent_type_text_edit: TextEdit = $InformationPanel/TextEditVBoxContainer/ParentTypeVBoxContainer/ParentTypeTextEdit
@onready var waypoint_connections_ids_v_box_container: VBoxContainer = $InformationPanel/TextEditVBoxContainer/WaypointConnectionsIDsVBoxContainer
@onready var waypoint_connections_ids_text_edit: TextEdit = $InformationPanel/TextEditVBoxContainer/WaypointConnectionsIDsVBoxContainer/WaypointConnectionsIDsTextEdit

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

var selected_structure: Structure
var starting_waypoint: Waypoint
var end_waypoint: Waypoint

# TODO add proper authentication
# Edit mode toggled
func _on_check_button_toggled(toggled_on: bool) -> void:
	Globals.edit_mode = toggled_on
	edit_mode_toggled.emit()
	change_text_edits()
	check_save_and_delete_buttons()

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

# Called when a structure is selected
func _select_structure(structure: Structure) -> void:
	# Change last selection colour back
	if selected_structure != null && selected_structure is Waypoint && selected_structure != starting_waypoint && selected_structure != end_waypoint:
		(selected_structure as Waypoint).change_colour(Color.LIGHT_GRAY)
	
	selected_structure = structure
	
	# Set common values
	if selected_structure != null:
		id_label.text = 'ID: ' + selected_structure.id
		longitude_text_edit.text = str(selected_structure.longitude)
		latitude_text_edit.text = str(selected_structure.latitude)
	else:
		id_label.text = 'ID: '
		longitude_text_edit.text = ""
		latitude_text_edit.text = ""
	
	name_v_box_container.visible = false
	description_v_box_container.visible = false
	building_letter_v_box_container.visible = false
	lecturers_v_box_container.visible = false
	floor_number_v_box_container.visible = false
	feature_type_v_box_container.visible = false
	parent_id_v_box_container.visible = false
	parent_type_v_box_container.visible = false
	waypoint_connections_ids_v_box_container.visible = false
	
	waypoints_updated_time_label.visible = false
	buildings_updated_time_label.visible = false
	rooms_updated_time_label.visible = false
	
	# TODO for now only use Waypoints for pathfinding
	start_button.disabled = true
	target_button.disabled = true
	
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
	name_text_edit.text = select_struct.structure_name
	name_v_box_container.visible = true
	description_text_edit.text = select_struct.description
	description_v_box_container.visible = true
	building_letter_text_edit.text = select_struct.building_letter
	building_letter_v_box_container.visible = true
	waypoints_updated_time_label.text = 'Waypoints Updated Time: ' + str(select_struct.waypoints_updated_time)
	waypoints_updated_time_label.visible = true
	rooms_updated_time_label.text = 'Rooms Updated Time: ' + str(select_struct.rooms_updated_time)
	rooms_updated_time_label.visible = true

# Show elements for Rooms
func show_room_details(select_struct: Room) -> void:
	name_text_edit.text = select_struct.structure_name
	name_v_box_container.visible = true
	description_text_edit.text = select_struct.description
	description_v_box_container.visible = true
	lecturers_text_edit.text = select_struct.lectures
	lecturers_v_box_container.visible = true
	floor_number_text_edit.text = str(select_struct.floor_number)
	floor_number_v_box_container.visible = true
	parent_id_text_edit.text = select_struct.parent_id
	parent_id_v_box_container.visible = true
	waypoints_updated_time_label.text = 'Waypoints Updated Time: ' + str(select_struct.waypoints_updated_time)
	waypoints_updated_time_label.visible = true

# Show elements for Waypoints
func show_waypoint_details(select_struct: Waypoint) -> void:
	floor_number_text_edit.text = str(select_struct.floor_number)
	floor_number_v_box_container.visible = true
	feature_type_text_edit.text = select_struct.feature_type
	feature_type_v_box_container.visible = true
	parent_id_text_edit.text = select_struct.parent_id
	parent_id_v_box_container.visible = true
	parent_type_text_edit.text = select_struct.parent_type
	parent_type_v_box_container.visible = true
	waypoint_connections_ids_text_edit.text = str(select_struct.waypoint_connections_ids)
	waypoint_connections_ids_v_box_container.visible = true

# Save variables on Save button press
func _on_save_button_pressed() -> void:
	if selected_structure == null:
		return
	if selected_structure is BaseMap:
		@warning_ignore("unsafe_call_argument")
		var details: Dictionary = {
			'longitude': {'doubleValue': float(longitude_text_edit.text)},
			'latitude': {'doubleValue': float(latitude_text_edit.text)},
			'waypoints_updated_time': {'integerValue': (selected_structure as BaseMap).waypoints_updated_time},
			'buildings_updated_time': {'integerValue': (selected_structure as BaseMap).buildings_updated_time}
		}
		selected_structure.update_details(details)
	elif selected_structure is Building:
		@warning_ignore("unsafe_call_argument")
		var details: Dictionary = {
			'longitude': {'doubleValue': float(longitude_text_edit.text)},
			'latitude': {'doubleValue': float(latitude_text_edit.text)},
			'name': {'stringValue': name_text_edit.text},
			'description': {'stringValue': description_text_edit.text},
			'building_letter': {'stringValue': building_letter_text_edit.text},
			'waypoints_updated_time': {'integerValue': (selected_structure as Building).waypoints_updated_time},
			'rooms_updated_time': {'integerValue': (selected_structure as Building).rooms_updated_time}
		}
		selected_structure.update_details(details)
	elif selected_structure is Room:
		@warning_ignore("unsafe_call_argument")
		var details: Dictionary = {
			'longitude': {'doubleValue': float(longitude_text_edit.text)},
			'latitude': {'doubleValue': float(latitude_text_edit.text)},
			'floor_number': {'integerValue': int(floor_number_text_edit.text)},
			'parent_id': {'stringValue': parent_id_text_edit.text},
			'name': {'stringValue': name_text_edit.text},
			'description': {'stringValue': description_text_edit.text},
			'lecturers': {'stringValue': lecturers_text_edit.text},
			'waypoints_updated_time': {'integerValue': (selected_structure as Room).waypoints_updated_time}
		}
		selected_structure.update_details(details)
	elif selected_structure is Waypoint:
		var connection_array: Array[Dictionary]
		@warning_ignore("unsafe_call_argument")
		var waypoint_connection_text_array: Array = str_to_var(waypoint_connections_ids_text_edit.text)
		for waypoint_id: String in waypoint_connection_text_array:
			connection_array.append({'stringValue': waypoint_id})
		
		@warning_ignore("unsafe_call_argument")
		var details: Dictionary = {
			'longitude': {'doubleValue': float(longitude_text_edit.text)},
			'latitude': {'doubleValue': float(latitude_text_edit.text)},
			'floor_number': {'integerValue': int(floor_number_text_edit.text)},
			'feature_type': {'stringValue': feature_type_text_edit.text},
			'parent_id': {'stringValue': parent_id_text_edit.text},
			'parent_type': {'stringValue': parent_type_text_edit.text},
			'waypoint_connections_ids': {'arrayValue': {'values': connection_array}}
		}
		selected_structure.update_details(details)


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
	Globals.pathfinder.do_pathfinding(starting_waypoint, end_waypoint)


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
		selected_structure = null

# Open up choosing window
func _on_add_button_pressed() -> void:
	if selected_structure is not Waypoint:
		building_button.visible = false
		room_button.visible = false
		if selected_structure is BaseMap:
			building_button.visible = true
		elif selected_structure is Building:
			room_button.visible = true
		add_structure_panel.visible = false

# Spawn the structure selected
func _on_building_button_pressed() -> void:
	if selected_structure is not Waypoint:
		spawn_specific_structure.emit(selected_structure, Structures.BuildingStruct)


func _on_room_button_pressed() -> void:
	if selected_structure is not Waypoint:
		spawn_specific_structure.emit(selected_structure, Structures.RoomStruct)


func _on_waypoint_button_pressed() -> void:
	if selected_structure is not Waypoint:
		spawn_specific_structure.emit(selected_structure, Structures.WaypointStruct)

# Close structure select screen
func _on_add_structure_cancel_button_pressed() -> void:
	add_structure_panel.visible = true


func _on_structure_spawner_select_spawned_structure(structure: Structure) -> void:
	_select_structure(structure)
