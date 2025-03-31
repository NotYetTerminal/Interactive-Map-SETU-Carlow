extends Node3D
class_name BuildingTextureNode


func update_visibility() -> void:
	var index: int = 1
	for node_3d: Node3D in get_children():
		if index == Globals.current_floor:
			node_3d.visible = true
		else:
			node_3d.visible = false
		index += 1
