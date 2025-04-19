extends Sprite3D
class_name FeatureSprite3D

@export var feature_images_dictionary: Dictionary[String, CompressedTexture2D]
@onready var cylinder_backround_mesh_instance_3d: MeshInstance3D = $MeshInstance3D


func set_feature_image(feature: String) -> bool:
	if feature_images_dictionary.has(feature):
		texture = feature_images_dictionary[feature]
		if feature == "Closed":
			cylinder_backround_mesh_instance_3d.visible = false
		else:
			cylinder_backround_mesh_instance_3d.visible = true
		return true
	else:
		texture = null
		cylinder_backround_mesh_instance_3d.visible = false
		return false


func change_texture_colour(new_colour: Color) -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color.BLACK
	material.metallic_specular = 0
	material.emission_enabled = true
	material.emission = new_colour
	cylinder_backround_mesh_instance_3d.set_surface_override_material(0, material)
