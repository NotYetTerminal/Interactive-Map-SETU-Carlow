extends Structure
class_name AndroidLocationTracker

# OS Location Tracking
var gps_provider: Object

@onready var accuracy_mesh_instance_3d: MeshInstance3D = $AccuracyMeshInstance3D


func _ready() -> void:
	var os_name: String = OS.get_name()
	if os_name == "Android" or (os_name == "Web" and OS.has_feature("web_android")):
		visible = true
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
		gps_provider.onLocationUpdates.connect(location_listener)
		@warning_ignore("unsafe_method_access")
		gps_provider.StartListening()


func location_listener(location_data: Dictionary) -> void:
	print(location_data)
	longitude = location_data["longitude"]
	latitude = location_data["latitude"]
	set_structure_global_position()
	var accuracy_level: float = location_data["accuracy"]
	accuracy_mesh_instance_3d.scale = Vector3(accuracy_level, accuracy_level, accuracy_level)
