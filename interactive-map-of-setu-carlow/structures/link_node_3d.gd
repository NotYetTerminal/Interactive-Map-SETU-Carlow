extends Node3D
class_name Link

var target_waypoint: Waypoint

func _process(_delta: float) -> void:
	if target_waypoint != null:
		look_at(target_waypoint.global_position)
		scale.z = global_position.distance_to(target_waypoint.global_position) / 2

# Change colour of Link from parent Waypoint
func change_colour(new_colour: Color) -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = new_colour
	var mesh_instance: MeshInstance3D = $MeshInstance3D
	mesh_instance.set_surface_override_material(0, material)
