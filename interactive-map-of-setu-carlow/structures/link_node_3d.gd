extends Node3D
class_name Link

var target_waypoint: Waypoint
var current_colour: Color

@onready var link_holder_node_3d: Node3D = $LinkHolderNode3D
@onready var mesh_instance_3d: MeshInstance3D = $LinkHolderNode3D/MeshInstance3D
@onready var feature_sprite_3d: FeatureSprite3D = $FeatureSprite3D

@onready var arrow_holder_node_3d: Node3D = $ArrowHolderNode3D
var arrow_active: bool = false
var feature_active: bool = false


func set_link_holder_visibility(seen: bool) -> void:
	link_holder_node_3d.visible = seen


func set_arrow_holder_visibility(seen: bool) -> void:
	arrow_holder_node_3d.visible = seen and not feature_active


func set_texture_visibility(seen: bool) -> void:
	feature_sprite_3d.visible = seen


func set_target_waypoint_and_feature(new_target_waypoint: Waypoint, feature: String) -> void:
	target_waypoint = new_target_waypoint
	if target_waypoint != null:
		if target_waypoint.global_position != global_position:
			look_at(target_waypoint.global_position)
		var half_distance_to_other: float = global_position.distance_to(target_waypoint.global_position) / 2
		link_holder_node_3d.scale.z = half_distance_to_other
		arrow_holder_node_3d.position.z = -half_distance_to_other

		if feature == "Stairs":
			var parent_waypoint: Waypoint = get_parent()
			if target_waypoint.floor_number > parent_waypoint.floor_number:
				feature = "Upstairs"
			elif target_waypoint.floor_number < parent_waypoint.floor_number:
				feature = "Downstairs"
		elif feature == 'Elevator' and target_waypoint.floor_number == 3:
			feature = 'None'

		feature_active = feature_sprite_3d.set_feature_image(feature)
		feature_sprite_3d.position.z = -half_distance_to_other
		feature_sprite_3d.global_rotation = Vector3(0, PI, 0)

		# Hide arrows if the feature is shown
		arrow_holder_node_3d.visible = not feature_active

# Change colour of Link from parent Waypoint
func change_colour(new_colour: Color) -> void:
	current_colour = new_colour
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = new_colour
	mesh_instance_3d.set_surface_override_material(0, material)

	if new_colour == Color.DEEP_SKY_BLUE:
		feature_sprite_3d.change_texture_colour(Color.YELLOW)
	else:
		feature_sprite_3d.change_texture_colour(Color.WHITE)
