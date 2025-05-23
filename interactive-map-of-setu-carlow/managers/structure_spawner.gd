extends Node

# Used for distinguishing different structure types
enum Structures { BuildingStruct, RoomStruct, WaypointStruct }
const BuildingStruct: int = 1
const RoomStruct: int = 2
const WaypointStruct: int = 3

# Variables for instantiating scenes
@export var base_map_scene: PackedScene
@export var building_scene: PackedScene
@export var room_scene: PackedScene
@export var waypoint_scene: PackedScene

@export var pathfinder: Pathfinder
@export var building_manager: BuildingManager
@export var room_manager: RoomManager

# Signal to Pathfinder to connect Waypoints
signal all_structures_done
# Signal to UI to select structure created
signal select_spawned_structure(structure: Structure)

# Create and render structures after map data is loaded
func _on_firebase_connector_map_data_loaded() -> void:
	print("Starting spawn")
	# Spawn BaseMap
	spawn_base_map(Globals.offline_data)
	all_structures_done.emit()


func spawn_base_map(map_data: Dictionary) -> void:
	var base_map_id: String = map_data.keys()[0]
	var base_map_data: Dictionary = map_data[base_map_id]

	# Save base location
	Globals.base_longitude = base_map_data["longitude"]
	Globals.base_latitude = base_map_data["latitude"]

	# Create new scene
	var new_base_map: BaseMap = base_map_scene.instantiate()
	new_base_map.saved = true
	get_parent().add_child(new_base_map)
	var _fields: Array[String] = new_base_map.save_details(base_map_id, base_map_data)

	if base_map_data.has('Waypoints'):
		# Spawn Waypoints
		for waypoint_id: String in base_map_data["Waypoints"]:
			var structure_data: Dictionary = base_map_data["Waypoints"][waypoint_id]
			var structure: Structure = spawn_structure(waypoint_id, structure_data, new_base_map, Structures.WaypointStruct)
			structure.saved = true

	if base_map_data.has('Buildings'):
		# Spawn Buildings
		for building_id: String in base_map_data["Buildings"]:
			var structure_data: Dictionary = base_map_data["Buildings"][building_id]
			spawn_building(building_id, structure_data, new_base_map)


func spawn_building(building_id: String, building_data: Dictionary, parent: Structure) -> void:
	# Spawn this building
	var parent_building: Structure = spawn_structure(building_id, building_data, parent, Structures.BuildingStruct)
	parent_building.saved = true

	if building_data.has('Waypoints'):
		# Spawn Waypoints
		for waypoint_id: String in building_data["Waypoints"]:
			var structure_data: Dictionary = building_data["Waypoints"][waypoint_id]
			var structure: Structure = spawn_structure(waypoint_id, structure_data, parent_building, Structures.WaypointStruct)
			structure.saved = true

	if building_data.has('Rooms'):
		# Spawn Rooms
		for room_id: String in building_data["Rooms"]:
			var structure_data: Dictionary = building_data["Rooms"][room_id]
			spawn_room(room_id, structure_data, parent_building)


func spawn_room(room_id: String, room_data: Dictionary, parent: Structure) -> void:
	# Spawn this room
	var parent_room: Structure = spawn_structure(room_id, room_data, parent, Structures.RoomStruct)
	parent_room.saved = true

	if room_data.has('Waypoints'):
		# Spawn Waypoints
		for waypoint_id: String in room_data["Waypoints"]:
			var structure_data: Dictionary = room_data["Waypoints"][waypoint_id]
			var structure: Structure = spawn_structure(waypoint_id, structure_data, parent_room, Structures.WaypointStruct)
			structure.saved = true


func spawn_structure(structure_id: String, structure_data: Dictionary, parent: Structure, structure_type: Structures) -> Structure:
	# Create new scene
	var new_structure: Structure
	match structure_type:
		Structures.BuildingStruct:
			new_structure = building_scene.instantiate()
			# Add to Buildings holder
			parent.get_child(1).add_child(new_structure)
		Structures.RoomStruct:
			new_structure = room_scene.instantiate()
			# Add to Rooms holder
			parent.get_child(1).add_child(new_structure)
			new_structure.update_visibility()
		Structures.WaypointStruct:
			new_structure = waypoint_scene.instantiate()
			# Add to Waypoints holder
			parent.get_child(0).add_child(new_structure)
			new_structure.update_visibility()

	var _fields: Array[String] = new_structure.save_details(structure_id, structure_data)

	# Add structure to manager
	match structure_type:
		Structures.BuildingStruct:
			building_manager.add_new_building(new_structure as Building)
		Structures.RoomStruct:
			room_manager.add_new_room(new_structure as Room)
		Structures.WaypointStruct:
			pathfinder.add_new_waypoint(new_structure as Waypoint)

	return new_structure


func _on_ui_root_spawn_specific_structure(parent: Structure, structure_type: Structures) -> void:
	var structure_id: String
	var default_data: Dictionary = {
		'longitude': parent.longitude + 0.0001,
		'latitude': parent.latitude,
	}
	# Assign an id for new structure
	match structure_type:
		Structures.BuildingStruct:
			structure_id = "Building_"
			default_data['name'] = ''
			default_data['description'] = ''
			default_data['building_letter'] = ''

			default_data['waypoints_updated_time'] = 0
			default_data['rooms_updated_time'] = 0
		Structures.RoomStruct:
			structure_id = "Room_"
			default_data['name'] = ''
			default_data['description'] = ''
			default_data['lecturers'] = 'None'
			default_data['floor_number'] = Globals.current_floor

			default_data['waypoints_updated_time'] = 0
		Structures.WaypointStruct:
			structure_id = "Waypoint_"
			if parent is Room:
				default_data['floor_number'] = (parent as Room).floor_number
			else:
				default_data['floor_number'] = Globals.current_floor
			default_data['waypoint_connections'] = {}

	structure_id += str(int(Time.get_unix_time_from_system()))

	var structure: Structure = spawn_structure(structure_id, default_data, parent, structure_type)
	structure.update_visibility()
	structure.mouse_editing = true
	select_spawned_structure.emit(structure)
