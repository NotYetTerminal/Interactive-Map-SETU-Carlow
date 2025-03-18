extends Node3D
class_name BuildingTextureNode


func update_visibility() -> void:
	var index: int = 1
	for mesh_instance_3d: MeshInstance3D in get_children():
		if index == Globals.current_floor:
			mesh_instance_3d.visible = true
		else:
			mesh_instance_3d.visible = false
		index += 1
