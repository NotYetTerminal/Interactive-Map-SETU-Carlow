extends Node
class_name BuildingManager

# Contains { building_id: String, building: Building }
var _all_buildings: Dictionary[String, Building] = {}


func add_new_building(new_building: Building) -> void:
	_all_buildings[new_building.id] = new_building


func get_building(building_id: String) -> Building:
	return _all_buildings.get(building_id)


func get_all_buildings() -> Array:
	return _all_buildings.values()


func _on_camera_3d_new_zoom_level(zoom_level: float) -> void:
	for building: Building in _all_buildings.values():
		building.set_icon_scale(zoom_level)
