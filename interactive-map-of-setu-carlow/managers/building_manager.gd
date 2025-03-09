extends Node
class_name BuildingManager

# Contains { building_id: String, building: Building }
var _all_buildings: Dictionary[String, Building] = {}


func add_new_building(new_building: Building) -> void:
	_all_buildings[new_building.id] = new_building


func get_all_buildings() -> Array:
	return _all_buildings.values()
