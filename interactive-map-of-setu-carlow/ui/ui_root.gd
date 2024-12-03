extends Control

signal edit_mode_toggled

@export var labels_container: VBoxContainer

@onready var structure_label: Label = $VBoxContainer2/StructureTypeLabel
@onready var save_button: Button = $VBoxContainer2/SaveButton

var selected_structure: Structure

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
	for scene: Control in $VBoxContainer2.get_children():
		if scene is TextEdit:
			scene.editable = Globals.edit_mode
		if scene is VBoxContainer:
			for inner_scene: Control in scene.get_children():
				if inner_scene is TextEdit:
					inner_scene.editable = Globals.edit_mode

# Called when a structure is selected
func _on_Globals_select_structure(structure: Structure) -> void:
	selected_structure = structure
	# Set common values
	$VBoxContainer2/IDLabel.text = 'ID: ' + selected_structure.id
	$VBoxContainer2/LongitudeTextEdit.text = str(selected_structure.longitude)
	$VBoxContainer2/LatitudeTextEdit.text = str(selected_structure.latitude)
	
	$VBoxContainer2/BaseMapVBoxContainer.visible = false
	$VBoxContainer2/BuildingVBoxContainer.visible = false
	$VBoxContainer2/RoomVBoxContainer.visible = false
	$VBoxContainer2/WaypointVBoxContainer.visible = false
	
	# Set individual ones
	if selected_structure is BaseMap:
		structure_label.text = 'Base Map'
		show_base_map_details(selected_structure)
		$VBoxContainer2/BaseMapVBoxContainer.visible = true
	elif selected_structure is Building:
		structure_label.text = 'Building'
		show_building_details(selected_structure)
		$VBoxContainer2/BuildingVBoxContainer.visible = true
	elif selected_structure is Room:
		structure_label.text = 'Room'
		show_room_details(selected_structure)
		$VBoxContainer2/RoomVBoxContainer.visible = true
	elif selected_structure is WaypointStructure:
		structure_label.text = 'Waypoint'
		show_waypoint_details(selected_structure)
		$VBoxContainer2/WaypointVBoxContainer.visible = true

func show_base_map_details(selected_structure: BaseMap) -> void:
	$VBoxContainer2/BaseMapVBoxContainer/WaypointsUpdatedTimeLabel.text = 'Waypoints Updated Time: ' + str(selected_structure.waypoints_updated_time)
	$VBoxContainer2/BaseMapVBoxContainer/BuildingsUpdatedTimeLabel.text = 'Buildings Updated Time: ' + str(selected_structure.buildings_updated_time)

func show_building_details(selected_structure: Building) -> void:
	$VBoxContainer2/BuildingVBoxContainer/NameTextEdit.text = selected_structure.building_name
	$VBoxContainer2/BuildingVBoxContainer/DescriptionTextEdit.text = selected_structure.description
	$VBoxContainer2/BuildingVBoxContainer/BuildingLetterTextEdit.text = selected_structure.building_letter
	$VBoxContainer2/BuildingVBoxContainer/WaypointsUpdatedTimeLabel.text = 'Waypoints Updated Time: ' + str(selected_structure.waypoints_updated_time)
	$VBoxContainer2/BuildingVBoxContainer/RoomsUpdatedTimeLabel.text = 'Rooms Updated Time: ' + str(selected_structure.rooms_updated_time)

func show_room_details(selected_structure: Room) -> void:
	$VBoxContainer2/RoomVBoxContainer/FloorNumberTextEdit.text = str(selected_structure.floor_number)
	$VBoxContainer2/RoomVBoxContainer/ParentIDTextEdit.text = selected_structure.parent_id
	$VBoxContainer2/RoomVBoxContainer/NameTextEdit.text = selected_structure.room_name
	$VBoxContainer2/RoomVBoxContainer/DescriptionTextEdit.text = selected_structure.description
	$VBoxContainer2/RoomVBoxContainer/LecturersTextEdit.text = selected_structure.lectures
	$VBoxContainer2/RoomVBoxContainer/WaypointsUpdatedTimeLabel.text = 'Waypoints Updated Time: ' + str(selected_structure.waypoints_updated_time)

func show_waypoint_details(selected_structure: WaypointStructure) -> void:
	$VBoxContainer2/WaypointVBoxContainer/FloorNumberTextEdit.text = str(selected_structure.floor_number)
	$VBoxContainer2/WaypointVBoxContainer/FeatureTypeTextEdit.text = selected_structure.feature_type
	$VBoxContainer2/WaypointVBoxContainer/ParentIDTextEdit.text = selected_structure.parent_id
	$VBoxContainer2/WaypointVBoxContainer/ParentTypeTextEdit.text = selected_structure.parent_type
	$VBoxContainer2/WaypointVBoxContainer/WaypointConnectionsIDsTextEdit.text = str(selected_structure.waypoint_connections_ids)

# Save variables on Save button press
func _on_save_button_pressed() -> void:
	if selected_structure is BaseMap:
		var details: Dictionary = {
			'longitude': {'doubleValue': float($VBoxContainer2/LongitudeTextEdit.text)},
			'latitude': {'doubleValue': float($VBoxContainer2/LatitudeTextEdit.text)},
			'waypoints_updated_time': {'integerValue': str(selected_structure.waypoints_updated_time)},
			'buildings_updated_time': {'integerValue': str(selected_structure.buildings_updated_time)}
		}
		selected_structure.update_details(details)
	elif selected_structure is Building:
		var details: Dictionary = {
			'longitude': {'doubleValue': float($VBoxContainer2/LongitudeTextEdit.text)},
			'latitude': {'doubleValue': float($VBoxContainer2/LatitudeTextEdit.text)},
			'name': {'stringValue': $VBoxContainer2/BuildingVBoxContainer/NameTextEdit.text},
			'description': {'stringValue': $VBoxContainer2/BuildingVBoxContainer/DescriptionTextEdit.text},
			'building_letter': {'stringValue': $VBoxContainer2/BuildingVBoxContainer/BuildingLetterTextEdit.text},
			'waypoints_updated_time': {'integerValue': str(selected_structure.waypoints_updated_time)},
			'rooms_updated_time': {'integerValue': str(selected_structure.rooms_updated_time)}
		}
		selected_structure.update_details(details)
	elif selected_structure is Room:
		var details: Dictionary = {
			'longitude': {'doubleValue': float($VBoxContainer2/LongitudeTextEdit.text)},
			'latitude': {'doubleValue': float($VBoxContainer2/LatitudeTextEdit.text)},
			'floor_number': {'integerValue': $VBoxContainer2/RoomVBoxContainer/FloorNumberTextEdit.text},
			'parent_id': {'stringValue': $VBoxContainer2/RoomVBoxContainer/ParentIDTextEdit.text},
			'name': {'stringValue': $VBoxContainer2/RoomVBoxContainer/NameTextEdit.text},
			'description': {'stringValue': $VBoxContainer2/RoomVBoxContainer/DescriptionTextEdit.text},
			'lecturers': {'stringValue': $VBoxContainer2/RoomVBoxContainer/LecturersTextEdit.text},
			'waypoints_updated_time': {'integerValue': str(selected_structure.waypoints_updated_time)}
		}
		selected_structure.update_details(details)
	elif selected_structure is WaypointStructure:
		var connection_array: Array[Dictionary]
		var waypoint_connections_text_array: Array[String] = str_to_var($VBoxContainer2/WaypointVBoxContainer/WaypointConnectionsIDsTextEdit.text)
		for waypoint_id: String in waypoint_connections_text_array:
			connection_array.append({'stringValue': waypoint_id})
		
		var details: Dictionary = {
			'longitude': {'doubleValue': float($VBoxContainer2/LongitudeTextEdit.text)},
			'latitude': {'doubleValue': float($VBoxContainer2/LatitudeTextEdit.text)},
			'floor_number': {'integerValue': $VBoxContainer2/WaypointVBoxContainer/FloorNumberTextEdit.text},
			'feature_type': {'stringValue': $VBoxContainer2/WaypointVBoxContainer/FeatureTypeTextEdit.text},
			'parent_id': {'stringValue': $VBoxContainer2/WaypointVBoxContainer/ParentIDTextEdit.text},
			'parent_type': {'stringValue': $VBoxContainer2/WaypointVBoxContainer/ParentTypeTextEdit.text},
			'waypoint_connection_ids': {'arrayValue': {'values': connection_array}}
		}
		selected_structure.update_details(details)
