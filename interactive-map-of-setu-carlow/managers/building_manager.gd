extends Node
class_name BuildingManager

# Contains { building_id: String: building: Building }
var _all_buildings: Dictionary = {}

func add_new_building(new_building: Building) -> void:
	_all_buildings[new_building.id] = new_building

func get_building(building_id: String) -> Building:
	return _all_buildings[building_id]
