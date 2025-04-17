extends Structure
class_name AndroidLocationTracker

signal snap_camera(android_position_x: float, android_position_z: float)

# OS Location Tracking
var gps_provider: Object

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var accuracy_mesh_instance_3d: MeshInstance3D = $AccuracyMeshInstance3D


func _ready() -> void:
	var os_name: String = OS.get_name()
	if os_name == "Android" or (os_name == "Web" and OS.has_feature("web_android")):
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
	if not visible:
		visible = true
	print(location_data)
	longitude = location_data["longitude"]
	latitude = location_data["latitude"]
	set_structure_global_position()
	var accuracy_level: float = min(location_data["accuracy"], 90)
	accuracy_mesh_instance_3d.scale = Vector3(accuracy_level, accuracy_level, accuracy_level)


func _on_camera_3d_new_zoom_level(zoom_level: float) -> void:
	mesh_instance_3d.scale = Vector3(zoom_level, zoom_level, zoom_level)


func _on_ui_root_snap_camera_to_location() -> void:
	snap_camera.emit(position.x, position.z)
