extends Node

# Used for distinguishing different structure types
enum Structures { BuildingStruct, RoomStruct, WaypointStruct }
const BuildingStruct: int = 1
const RoomStruct: int = 2
const WaypointStruct: int = 3

# Save base values
var base_longitude: float
var base_latitude: float

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

# Create and render structures after map data is loaded
func _on_firebase_connector_map_data_loaded(map_data: Dictionary) -> void:
	print("YAY")
	# Spawn BaseMap
	spawn_base_map(map_data)
	all_structures_done.emit()

func spawn_base_map(map_data: Dictionary) -> void:
	var base_map_id: String = map_data.keys()[0]
	
	# Save base location
	base_longitude = map_data[base_map_id]["longitude"]["doubleValue"]
	base_latitude = map_data[base_map_id]["latitude"]["doubleValue"]
	
	# Create new scene
	var new_base_map: BaseMap = base_map_scene.instantiate()
	@warning_ignore("unsafe_call_argument")
	new_base_map.save_details(base_map_id, map_data[base_map_id])
	get_parent().add_child(new_base_map)
	Globals.base_map = new_base_map
	
	# Spawn Waypoints
	for waypoint_id: String in map_data[base_map_id]["Waypoints"]:
		@warning_ignore("unsafe_call_argument")
		@warning_ignore("return_value_discarded")
		spawn_structure(waypoint_id, map_data[base_map_id]["Waypoints"][waypoint_id], new_base_map, Structures.WaypointStruct) 
	
	# Spawn Buildings
	for building_id: String in map_data[base_map_id]["Buildings"]:
		@warning_ignore("unsafe_call_argument")
		spawn_building(building_id, map_data[base_map_id]["Buildings"][building_id], new_base_map)

func spawn_building(building_id: String, building_data: Dictionary, parent: Structure) -> void:
	# Spawn this building
	var parent_building: Structure = spawn_structure(building_id, building_data, parent, Structures.BuildingStruct)
	
	# Spawn Waypoints
	for waypoint_id: String in building_data["Waypoints"]:
		@warning_ignore("unsafe_call_argument")
		@warning_ignore("return_value_discarded")
		spawn_structure(waypoint_id, building_data["Waypoints"][waypoint_id], parent_building, Structures.WaypointStruct)
	
	# Spawn Rooms
	for room_id: String in building_data["Rooms"]:
		@warning_ignore("unsafe_call_argument")
		spawn_room(room_id, building_data["Rooms"][room_id], parent_building)

func spawn_room(room_id: String, room_data: Dictionary, parent: Structure) -> void:
	# Spawn this room
	var parent_room: Structure = spawn_structure(room_id, room_data, parent, Structures.RoomStruct)
	
	# Spawn Waypoints
	for waypoint_id: String in room_data["Waypoints"]:
		@warning_ignore("unsafe_call_argument")
		@warning_ignore("return_value_discarded")
		spawn_structure(waypoint_id, room_data["Waypoints"][waypoint_id], parent_room, Structures.WaypointStruct)

func spawn_structure(structure_id: String, structure_data: Dictionary, parent: Structure, structure_type: Structures) -> Structure:
	# Create new scene
	var new_structure: Structure
	match(structure_type):
		Structures.BuildingStruct:
			new_structure = building_scene.instantiate()
		Structures.RoomStruct:
			new_structure = room_scene.instantiate()
		Structures.WaypointStruct:
			new_structure = waypoint_scene.instantiate()
	
	@warning_ignore("unsafe_call_argument")
	new_structure.save_details(structure_id, structure_data)
	parent.add_child(new_structure)
	
	# Set global position
	new_structure.global_position = Vector3(new_structure.longitude - base_longitude, 0, new_structure.latitude - base_latitude)
	
	# Add structure to manager
	match(structure_type):
		Structures.BuildingStruct:
			@warning_ignore("unsafe_call_argument")
			building_manager.add_new_building(new_structure)
		Structures.RoomStruct:
			@warning_ignore("unsafe_call_argument")
			room_manager.add_new_room(new_structure)
		Structures.WaypointStruct:
			@warning_ignore("unsafe_call_argument")
			pathfinder.add_new_waypoint(new_structure)
	
	return new_structure