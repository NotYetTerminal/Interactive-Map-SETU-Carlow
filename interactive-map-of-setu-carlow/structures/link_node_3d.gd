extends Node3D
class_name Link

var target_waypoint: Waypoint
var current_colour: Color

@onready var link_holder_node_3d: Node3D = $LinkHolderNode3D
@onready var mesh_instance_3d: MeshInstance3D = $LinkHolderNode3D/MeshInstance3D
@onready var feature_sprite_3d: FeatureSprite3D = $FeatureSprite3D


func set_link_holder_visibility(seen: bool) -> void:
	link_holder_node_3d.visible = seen || current_colour == Color.GREEN


func set_texture_visibility(seen: bool) -> void:
	feature_sprite_3d.visible = seen


func set_target_waypoint_and_feature(new_target_waypoint: Waypoint, feature: String) -> void:
	target_waypoint = new_target_waypoint
	if target_waypoint != null:
		look_at(target_waypoint.global_position)
		var half_distance_to_other: float = global_position.distance_to(target_waypoint.global_position) / 2
		link_holder_node_3d.scale.z = half_distance_to_other
		
		if feature == "Stairs":
			var parent_waypoint: Waypoint = get_parent()
			if target_waypoint.floor_number > parent_waypoint.floor_number:
				feature = "Upstairs"
			elif target_waypoint.floor_number < parent_waypoint.floor_number:
				feature = "Downstairs"
		feature_sprite_3d.set_feature_image(feature)
		feature_sprite_3d.position.z = -half_distance_to_other
		feature_sprite_3d.global_rotation = Vector3(0, PI, 0)

# Change colour of Link from parent Waypoint
func change_colour(new_colour: Color) -> void:
	current_colour = new_colour
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = new_colour
	mesh_instance_3d.set_surface_override_material(0, material)
