extends Control

signal edit_mode_toggled

@export var labels_container: VBoxContainer

@onready var structure_label: Label = $Panel2/VBoxContainer2/StructureTypeLabel
@onready var save_button: Button = $Panel2/VBoxContainer2/SaveButton

var selected_structure: Structure
var starting_waypoint: Waypoint
var end_waypoint: Waypoint

func _ready() -> void:
	Globals.connect('select_structure', _on_Globals_select_structure)

# TODO add proper authentication
# Edit mode toggled
func _on_check_button_toggled(toggled_on: bool) -> void:
	Globals.edit_mode = toggled_on
	edit_mode_toggled.emit()
	change_text_edits()
	save_button.disabled = not Globals.edit_mode

# Change the editable status of all Text Edits
func change_text_edits() -> void:
	for scene: Control in $Panel2/VBoxContainer2.get_children():
		if scene is TextEdit:
			scene.editable = Globals.edit_mode
		if scene is VBoxContainer:
			for inner_scene: Control in scene.get_children():
				if inner_scene is TextEdit:
					inner_scene.editable = Globals.edit_mode

# Called when a structure is selected
func _on_Globals_select_structure(structure: Structure) -> void:
	# Change last selection colour back
	if selected_structure != null && selected_structure is Waypoint && selected_structure != starting_waypoint && selected_structure != end_waypoint:
		selected_structure.change_colour(Color.LIGHT_GRAY)
	
	selected_structure = structure
	
	# Set common values
	$Panel2/VBoxContainer2/IDLabel.text = 'ID: ' + selected_structure.id
	$Panel2/VBoxContainer2/LongitudeTextEdit.text = str(selected_structure.longitude)
	$Panel2/VBoxContainer2/LatitudeTextEdit.text = str(selected_structure.latitude)
	
	$Panel2/VBoxContainer2/BaseMapVBoxContainer.visible = false
	$Panel2/VBoxContainer2/BuildingVBoxContainer.visible = false
	$Panel2/VBoxContainer2/RoomVBoxContainer.visible = false
	$Panel2/VBoxContainer2/WaypointVBoxContainer.visible = false
	
	# TODO for now only use Waypoints for pathfinding
	$Panel/VBoxContainer/StartButton.disabled = true
	$Panel/VBoxContainer/TargetButton.disabled = true
	# Set individual ones
	if selected_structure is BaseMap:
		structure_label.text = 'Base Map'
		show_base_map_details(selected_structure)
		$Panel2/VBoxContainer2/BaseMapVBoxContainer.visible = true
	elif selected_structure is Building:
		structure_label.text = 'Building'
		show_building_details(selected_structure)
		$Panel2/VBoxContainer2/BuildingVBoxContainer.visible = true
	elif selected_structure is Room:
		structure_label.text = 'Room'
		show_room_details(selected_structure)
		$Panel2/VBoxContainer2/RoomVBoxContainer.visible = true
	elif selected_structure is Waypoint:
		selected_structure.change_colour(Color.BLACK)
		structure_label.text = 'Waypoint'
		show_waypoint_details(selected_structure)
		$Panel2/VBoxContainer2/WaypointVBoxContainer.visible = true
		$Panel/VBoxContainer/StartButton.disabled = false
		$Panel/VBoxContainer/TargetButton.disabled = false

func show_base_map_details(selected_structure: BaseMap) -> void:
	$Panel2/VBoxContainer2/BaseMapVBoxContainer/WaypointsUpdatedTimeLabel.text = 'Waypoints Updated Time: ' + str(selected_structure.waypoints_updated_time)
	$Panel2/VBoxContainer2/BaseMapVBoxContainer/BuildingsUpdatedTimeLabel.text = 'Buildings Updated Time: ' + str(selected_structure.buildings_updated_time)

func show_building_details(selected_structure: Building) -> void:
	$Panel2/VBoxContainer2/BuildingVBoxContainer/NameTextEdit.text = selected_structure.building_name
	$Panel2/VBoxContainer2/BuildingVBoxContainer/DescriptionTextEdit.text = selected_structure.description
	$Panel2/VBoxContainer2/BuildingVBoxContainer/BuildingLetterTextEdit.text = selected_structure.building_letter
	$Panel2/VBoxContainer2/BuildingVBoxContainer/WaypointsUpdatedTimeLabel.text = 'Waypoints Updated Time: ' + str(selected_structure.waypoints_updated_time)
	$Panel2/VBoxContainer2/BuildingVBoxContainer/RoomsUpdatedTimeLabel.text = 'Rooms Updated Time: ' + str(selected_structure.rooms_updated_time)

func show_room_details(selected_structure: Room) -> void:
	$Panel2/VBoxContainer2/RoomVBoxContainer/FloorNumberTextEdit.text = str(selected_structure.floor_number)
	$Panel2/VBoxContainer2/RoomVBoxContainer/ParentIDTextEdit.text = selected_structure.parent_id
	$Panel2/VBoxContainer2/RoomVBoxContainer/NameTextEdit.text = selected_structure.room_name
	$Panel2/VBoxContainer2/RoomVBoxContainer/DescriptionTextEdit.text = selected_structure.description
	$Panel2/VBoxContainer2/RoomVBoxContainer/LecturersTextEdit.text = selected_structure.lectures
	$Panel2/VBoxContainer2/RoomVBoxContainer/WaypointsUpdatedTimeLabel.text = 'Waypoints Updated Time: ' + str(selected_structure.waypoints_updated_time)

func show_waypoint_details(selected_structure: Waypoint) -> void:
	$Panel2/VBoxContainer2/WaypointVBoxContainer/FloorNumberTextEdit.text = str(selected_structure.floor_number)
	$Panel2/VBoxContainer2/WaypointVBoxContainer/FeatureTypeTextEdit.text = selected_structure.feature_type
	$Panel2/VBoxContainer2/WaypointVBoxContainer/ParentIDTextEdit.text = selected_structure.parent_id
	$Panel2/VBoxContainer2/WaypointVBoxContainer/ParentTypeTextEdit.text = selected_structure.parent_type
	$Panel2/VBoxContainer2/WaypointVBoxContainer/WaypointConnectionsIDsTextEdit.text = str(selected_structure.waypoint_connections_ids)

# Save variables on Save button press
func _on_save_button_pressed() -> void:
	if selected_structure is BaseMap:
		var details: Dictionary = {
			'longitude': {'doubleValue': float($Panel2/VBoxContainer2/LongitudeTextEdit.text)},
			'latitude': {'doubleValue': float($Panel2/VBoxContainer2/LatitudeTextEdit.text)},
			'waypoints_updated_time': {'integerValue': str(selected_structure.waypoints_updated_time)},
			'buildings_updated_time': {'integerValue': str(selected_structure.buildings_updated_time)}
		}
		selected_structure.update_details(details)
	elif selected_structure is Building:
		var details: Dictionary = {
			'longitude': {'doubleValue': float($Panel2/VBoxContainer2/LongitudeTextEdit.text)},
			'latitude': {'doubleValue': float($Panel2/VBoxContainer2/LatitudeTextEdit.text)},
			'name': {'stringValue': $Panel2/VBoxContainer2/BuildingVBoxContainer/NameTextEdit.text},
			'description': {'stringValue': $Panel2/VBoxContainer2/BuildingVBoxContainer/DescriptionTextEdit.text},
			'building_letter': {'stringValue': $Panel2/VBoxContainer2/BuildingVBoxContainer/BuildingLetterTextEdit.text},
			'waypoints_updated_time': {'integerValue': str(selected_structure.waypoints_updated_time)},
			'rooms_updated_time': {'integerValue': str(selected_structure.rooms_updated_time)}
		}
		selected_structure.update_details(details)
	elif selected_structure is Room:
		var details: Dictionary = {
			'longitude': {'doubleValue': float($Panel2/VBoxContainer2/LongitudeTextEdit.text)},
			'latitude': {'doubleValue': float($Panel2/VBoxContainer2/LatitudeTextEdit.text)},
			'floor_number': {'integerValue': $Panel2/VBoxContainer2/RoomVBoxContainer/FloorNumberTextEdit.text},
			'parent_id': {'stringValue': $Panel2/VBoxContainer2/RoomVBoxContainer/ParentIDTextEdit.text},
			'name': {'stringValue': $Panel2/VBoxContainer2/RoomVBoxContainer/NameTextEdit.text},
			'description': {'stringValue': $Panel2/VBoxContainer2/RoomVBoxContainer/DescriptionTextEdit.text},
			'lecturers': {'stringValue': $Panel2/VBoxContainer2/RoomVBoxContainer/LecturersTextEdit.text},
			'waypoints_updated_time': {'integerValue': str(selected_structure.waypoints_updated_time)}
		}
		selected_structure.update_details(details)
	elif selected_structure is Waypoint:
		var connection_array: Array[Dictionary]
		var waypoint_connection_text_array: Array = str_to_var($Panel2/VBoxContainer2/WaypointVBoxContainer/WaypointConnectionsIDsTextEdit.text)
		for waypoint_id: String in waypoint_connection_text_array:
			connection_array.append({'stringValue': waypoint_id})
		
		var details: Dictionary = {
			'longitude': {'doubleValue': float($Panel2/VBoxContainer2/LongitudeTextEdit.text)},
			'latitude': {'doubleValue': float($Panel2/VBoxContainer2/LatitudeTextEdit.text)},
			'floor_number': {'integerValue': $Panel2/VBoxContainer2/WaypointVBoxContainer/FloorNumberTextEdit.text},
			'feature_type': {'stringValue': $Panel2/VBoxContainer2/WaypointVBoxContainer/FeatureTypeTextEdit.text},
			'parent_id': {'stringValue': $Panel2/VBoxContainer2/WaypointVBoxContainer/ParentIDTextEdit.text},
			'parent_type': {'stringValue': $Panel2/VBoxContainer2/WaypointVBoxContainer/ParentTypeTextEdit.text},
			'waypoint_connections_ids': {'arrayValue': {'values': connection_array}}
		}
		selected_structure.update_details(details)


func _on_start_button_pressed() -> void:
	# If previously selected change back colour
	if starting_waypoint != null:
		starting_waypoint.change_colour(Color.LIGHT_GRAY)
	
	starting_waypoint = selected_structure
	$Panel/VBoxContainer/StartWaypointLabel.text = "Start: " + starting_waypoint.id
	starting_waypoint.change_colour(Color.ROYAL_BLUE)
	
	check_pathfinding_button()

func _on_target_button_pressed() -> void:
	# If previously selected change back colour
	if end_waypoint != null:
		end_waypoint.change_colour(Color.LIGHT_GRAY)
	
	end_waypoint = selected_structure
	$Panel/VBoxContainer/EndWaypointLabel.text = "End: " + end_waypoint.id
	end_waypoint.change_colour(Color.INDIAN_RED)
	
	check_pathfinding_button()

# Enable once both targets are set
func check_pathfinding_button() -> void:
	$Panel/VBoxContainer/PathfindingButton.disabled = starting_waypoint == null or end_waypoint == null


func _on_pathfinding_button_pressed() -> void:
	Globals.pathfinder.do_pathfinding(starting_waypoint, end_waypoint)


func _on_reset_button_pressed() -> void:
	# Reset start and end Waypoints labels
	if starting_waypoint != null:
		starting_waypoint.change_colour(Color.LIGHT_GRAY)
	starting_waypoint = null
	$Panel/VBoxContainer/StartWaypointLabel.text = "Start: "
	
	if end_waypoint != null:
		end_waypoint.change_colour(Color.LIGHT_GRAY)
	end_waypoint = null
	$Panel/VBoxContainer/EndWaypointLabel.text = "End: "
	
	check_pathfinding_button()
	
	# Reset all Waypoints used in last pathfinding
	Globals.pathfinder.reset()
