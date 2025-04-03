extends Node3D
class_name BuildingTextureNode


func update_visibility() -> bool:
	var index: int = 1
	var visible_floor: bool = false
	for node_3d: Node3D in get_children():
		if index == Globals.current_floor:
			node_3d.visible = true
			visible_floor = true
		else:
			node_3d.visible = false
		index += 1
	return visible_floor
