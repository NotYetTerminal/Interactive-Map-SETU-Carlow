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

var current_floor: int = 1

# Disable print statements on export
func _ready() -> void:
	var os_name: String = OS.get_name()
	if os_name == "Android" or os_name == "Web":
		Engine.print_to_stdout = false

# Load offline data
func load_offline_data() -> void:
	var file: FileAccess = FileAccess.open("user://offline_data", FileAccess.READ)
	if file != null and file.get_length() != 0:
		print("Loaded")
		offline_data = file.get_var()
	else:
		# The first time the application runs use the data included in the build export
		file = FileAccess.open("res://offline_data_cached", FileAccess.READ)
		if file != null:
			print("Loaded cache")
			offline_data = file.get_var()
			save_offline_data()

# Save data for both local and cloud
func save_data(id: String, fields: Array[String], parent_collection_path: String, global_structure_offline_data: Dictionary) -> void:
	save_offline_data()
	# Save data to cloud
	await firebaseConnector.save_map_data(id, fields, parent_collection_path, global_structure_offline_data)

# Save offline data
func save_offline_data() -> void:
	var file: FileAccess = FileAccess.open("user://offline_data", FileAccess.WRITE)
	if file != null and len(offline_data.keys()) != 0:
		print("Saved")
		var _error: bool = file.store_var(offline_data)

# Delete the structure according to id
func delete_structure(path: String, id: String) -> void:
	save_offline_data()
	# Delete structure from cloud
	await firebaseConnector.delete_structure(path, id)
