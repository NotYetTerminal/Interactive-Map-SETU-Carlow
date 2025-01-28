extends Node3D
class_name BuildingTextureNode


func update_visibility_by_floor_number(checking_floor_number: int) -> void:
	var index: int = 1
	for mesh_instance_3d: MeshInstance3D in get_children():
		if index == checking_floor_number:
			mesh_instance_3d.visible = true
		else:
			mesh_instance_3d.visible = false
		index += 1
