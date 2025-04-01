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

# Load offline data
func load_offline_data() -> void:
	var file: FileAccess = FileAccess.open("user://offline_data", FileAccess.READ)
	if file != null:
		print("Loaded")
		offline_data = file.get_var()
	else:
		# The first time the application runs use the data included in the build export
		file = FileAccess.open("offline_data_cached", FileAccess.READ)
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
	if file != null:
		print("Saved")
		var _error: bool = file.store_var(offline_data)

# Delete the structure according to id
func delete_structure(path: String, id: String) -> void:
	save_offline_data()
	# Delete structure from cloud
	await firebaseConnector.delete_structure(path, id)


# OS Location Tracking
var gps_provider: Object


func _ready() -> void:
	#The rest of your startup code goes here as usual
	var _result: int = get_tree().on_request_permissions_result.connect(permission_check)

	#NOTE: OS.request_permissions() should be called from a button the user actively touches after being informed of 
	#what the button will enable.  This is placed in _ready() only to indicate this must be called, and how to structure
	#handling the 2 paths code can follow after calling it.

	var allowed: bool = OS.request_permissions() 
	if allowed:
		enable_GPS()


func permission_check(permission_name: String, was_granted: bool) -> void:
	if permission_name == "android.permission.ACCESS_FINE_LOCATION" and was_granted == true:
		enable_GPS()


func enable_GPS() -> void:
	gps_provider = Engine.get_singleton("PraxisMapperGPSPlugin")
	if gps_provider != null:
		@warning_ignore("unsafe_property_access")
		@warning_ignore("unsafe_method_access")
		gps_provider.onLocationUpdates.connect(listener_function)
		@warning_ignore("unsafe_method_access")
		gps_provider.StartListening()


func listener_function(location_data: Dictionary) -> void:
	print(location_data)
