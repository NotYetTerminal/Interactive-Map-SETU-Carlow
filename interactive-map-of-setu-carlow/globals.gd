extends Node

# Whether edit mode is active
var edit_mode: bool = false

# Save base position
var base_longitude: float
var base_latitude: float

var pathfinder: Pathfinder
var base_map: BaseMap

# Offline data used to store map data
var offline_data: Dictionary

# Used for saving map data
var firebaseConnector: FirebaseConnector

# Used for various calculations, in meters
const EARTH_RADIUS: float = 6378137

# Load offline data
func load_offline_data() -> void:
	var file: FileAccess = FileAccess.open("user://offline_data.txt", FileAccess.READ)
	if file != null:
		print("Loaded")
		offline_data = file.get_var()

# Save data for both local and cloud
func save_data(id: String, fields: Array[String], parent_id: String, global_structure_offline_data: Dictionary) -> void:
	save_offline_data()
	# Save data to cloud
	await firebaseConnector.save_map_data(id, fields, parent_id, global_structure_offline_data)

# Save offline data
func save_offline_data() -> void:
	var file: FileAccess = FileAccess.open("user://offline_data.txt", FileAccess.WRITE)
	if file != null:
		print("Saved")
		file.store_var(offline_data)

# Delete the structure according to id
func delete_structure(path: String, id: String) -> void:
	save_offline_data()
	# Delete structure from cloud
	await firebaseConnector.delete_structure(path, id)
