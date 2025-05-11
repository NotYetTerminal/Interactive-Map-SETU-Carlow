extends Structure
class_name Building

var description: String
var building_letter: String

@onready var waypoints_node: Node3D = $Waypoints
@onready var rooms_node: Node3D = $Rooms

var waypoints_updated_time: int
var rooms_updated_time: int

# Contains textures for buildings { structure_name: String, texture_scene: PackedScene }
@export var map_textures_dictionary: Dictionary[String, PackedScene]

var building_texture_node: Node3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

var base_scale: Vector3 = Vector3(0.5, 0.5, 0.5)
var large_scale: Vector3 = Vector3(1, 1, 1)

# Save details from map_data
func save_details(id_in: String, details: Dictionary) -> Array[String]:
	id = id_in

	# When the structure is created no data is passed to it
	if details.is_empty():
		return []

	var changed_fields: Array[String] = [
		"longitude" if longitude != details["longitude"] else "",
		"latitude" if latitude != details["latitude"] else "",
		"name" if structure_name != details["name"] else "",
		"description" if description != details["description"] else "",
		"building_letter" if building_letter != details["building_letter"] else "",
		"waypoints_updated_time" if waypoints_updated_time != details["waypoints_updated_time"] else "",
		"rooms_updated_time" if rooms_updated_time != details["rooms_updated_time"] else ""
	]

	longitude = details["longitude"]
	latitude = details["latitude"]

	structure_name = details["name"]
	description = details["description"]
	building_letter = details["building_letter"]

	waypoints_updated_time = details["waypoints_updated_time"]
	rooms_updated_time = details["rooms_updated_time"]

	set_structure_global_position()
	add_map_texture()
	return changed_fields

# Update the details when editing
func update_details(details: Dictionary) -> void:
	var fields: Array[String] = save_details(id, details)
	var base_map: BaseMap = get_parent_structure()

	var buildings_dictionary: Dictionary = Globals.offline_data[base_map.id]
	if not buildings_dictionary.has('Buildings'):
		buildings_dictionary['Buildings'] = {}

	buildings_dictionary = buildings_dictionary['Buildings']
	if buildings_dictionary.has(id):
		var building_data: Dictionary = buildings_dictionary[id]
		if not building_data.has('Rooms'):
			building_data['Rooms'] = {}
		details['Rooms'] = building_data['Rooms']
		if not building_data.has('Waypoints'):
			building_data['Waypoints'] = {}
		details['Waypoints'] = building_data['Waypoints']

	buildings_dictionary[id] = details
	await Globals.save_data(id, fields, current_firestore_path(), details)

	saved = true
	base_map.update_buildings_time(int(Time.get_unix_time_from_system()))

# Used by children to update time
func update_rooms_time(new_time: int) -> void:
	rooms_updated_time = new_time
	var base_map: BaseMap = get_parent_structure()

	Globals.offline_data[base_map.id]['Buildings'][id]['rooms_updated_time'] = rooms_updated_time
	var structure_data: Dictionary = Globals.offline_data[base_map.id]['Buildings'][id]
	await Globals.save_data(id, ['rooms_updated_time'], current_firestore_path(), structure_data)

	base_map.update_buildings_time(rooms_updated_time)


func update_waypoints_time(new_time: int) -> void:
	waypoints_updated_time = new_time
	var base_map: BaseMap = get_parent_structure()

	Globals.offline_data[base_map.id]['Buildings'][id]['waypoints_updated_time'] = waypoints_updated_time
	var structure_data: Dictionary = Globals.offline_data[base_map.id]['Buildings'][id]
	await Globals.save_data(id, ['waypoints_updated_time'], current_firestore_path(), structure_data)

	base_map.update_buildings_time(waypoints_updated_time)

# Set global position, and update children
func set_structure_global_position() -> void:
	super.set_structure_global_position()
	for waypoint: Waypoint in waypoints_node.get_children():
		waypoint.set_structure_global_position()
	for room: Room in rooms_node.get_children():
		room.set_structure_global_position()

# Delete the structure and data related to it
func delete_itself() -> void:
	# Delete all Rooms in the Building
	for room: Room in rooms_node.get_children():
		await room.delete_itself()
	# Delete all Waypoints in the Building
	for waypoint: Waypoint in waypoints_node.get_children():
		await waypoint.delete_itself()

	var base_map: BaseMap = get_parent_structure()
	var buildings_dictionary: Dictionary = Globals.offline_data[base_map.id]['Buildings']
	var _erased: bool = buildings_dictionary.erase(id)
	base_map.update_buildings_time(int(Time.get_unix_time_from_system()))

	await Globals.delete_structure(base_map.id + '/Buildings', id)
	self.queue_free()

# Used by Waypoint children to get data
func get_offline_data_waypoints() -> Dictionary:
	var base_map: BaseMap = get_parent_structure()
	var structure_dictionary: Dictionary = Globals.offline_data[base_map.id]['Buildings'][id]
	if not structure_dictionary.has('Waypoints'):
		structure_dictionary['Waypoints'] = {}
	return structure_dictionary['Waypoints']


func get_parent_structure() -> BaseMap:
	return get_parent().get_parent()


# Used by Waypoint children to get path of parent
func get_firestore_path() -> String:
	return current_firestore_path() + "/" + id


func current_firestore_path() -> String:
	var base_map: BaseMap = get_parent_structure()
	return base_map.get_firestore_path() + "/Buildings"

# Adds in the texture for the building
func add_map_texture() -> void:
	if map_textures_dictionary.has(structure_name):
		if building_texture_node == null:
			var building_texture_scene: PackedScene = map_textures_dictionary[structure_name]
			building_texture_node = building_texture_scene.instantiate()
			add_child(building_texture_node)
	else:
		print("Not found key: " + structure_name)
		print(map_textures_dictionary)

# Used by Pathfinder to get Waypoint in the Building
func get_closest_waypoint() -> Waypoint:
	var closest_distance: float = 10000
	var closest_waypoint: Waypoint
	for waypoint: Waypoint in waypoints_node.get_children():
		if waypoint.floor_number == 1:
			var distance: float = global_position.distance_to(waypoint.global_position) + (waypoint.floor_number - 1)
			if distance < closest_distance:
				closest_distance = distance
				closest_waypoint = waypoint
	return closest_waypoint


func update_visibility() -> void:
	for waypoint: Waypoint in waypoints_node.get_children():
		waypoint.update_visibility()
	for room: Room in rooms_node.get_children():
		room.update_visibility()
	# Change Building texture
	if building_texture_node != null:
		var floor_available: bool = (building_texture_node as BuildingTextureNode).update_visibility()
		mesh_instance_3d.visible = floor_available


func set_mesh_colour(new_colour: Color = Color("6b33cc")) -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color.BLACK
	material.metallic_specular = 0
	material.emission_enabled = true
	material.emission = new_colour
	mesh_instance_3d.set_surface_override_material(0, material)
	if new_colour == Color("6b33cc"):
		mesh_instance_3d.scale = base_scale
		collision_shape_3d.scale = base_scale
	else:
		mesh_instance_3d.scale = large_scale
		collision_shape_3d.scale = large_scale
