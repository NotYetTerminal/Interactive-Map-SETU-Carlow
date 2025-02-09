extends Sprite3D
class_name FeatureSprite3D

@export var feature_images_dictionary: Dictionary
@onready var cylinder_backround_mesh_instance_3d: MeshInstance3D = $MeshInstance3D


func set_feature_image(feature: String) -> void:
	if feature_images_dictionary.has(feature):
		texture = feature_images_dictionary[feature]
		if feature == "Closed":
			cylinder_backround_mesh_instance_3d.visible = false
		else:
			cylinder_backround_mesh_instance_3d.visible = true
	else:
		texture = null
		cylinder_backround_mesh_instance_3d.visible = false
