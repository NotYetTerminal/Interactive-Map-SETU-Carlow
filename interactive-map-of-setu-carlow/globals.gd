extends Node

# Whether edit mode is active
var edit_mode: bool = false

# Save base position
var base_longitude: float
var base_latitude: float

var pathfinder: Pathfinder

# Currently selected structure
signal select_structure(selected_structure: Structure)

# Offline data used to store map data
# TODO change this to an Object
var offline_data: Dictionary

# Load offline data
func load_offline_data() -> void:
	var file: FileAccess = FileAccess.open("user://offline_data.txt", FileAccess.READ)
	if file != null:
		print("Loaded")
		offline_data = file.get_var()

# Save offline data
func save_offline_data() -> void:
	var file: FileAccess = FileAccess.open("user://offline_data.txt", FileAccess.WRITE)
	if file != null:
		print("Saved")
		file.store_var(offline_data)
