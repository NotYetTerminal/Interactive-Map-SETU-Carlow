extends Panel
class_name SearchPanel

signal set_from_search_structure(structure: Structure)
signal set_to_search_structure(structure: Structure)

var building_manager: BuildingManager
var room_manager: RoomManager

@export var search_item_h_box_container_scene: PackedScene
@onready var v_box_container: VBoxContainer = $ScrollContainer/VBoxContainer

var search_item_h_box_containers: Array[SearchItemHBoxContainer] = []
var h_seperators: Array[HSeparator] = []
var top_search_bar_active: bool = true


func set_managers(building_man: BuildingManager, room_man: RoomManager) -> void:
	building_manager = building_man
	room_manager = room_man


func general_search(searching_text: String) -> Array[Structure]:
	searching_text = searching_text.to_lower()
	var building_array: Array = building_manager.get_all_buildings()
	var room_array: Array = room_manager.get_all_rooms()
	
	# Longer text search
	if searching_text.length() > 2:
		var name_match_array: Array[Structure] = []
		var lecturers_match_array: Array[Structure] = []
		# Stores the amount of times text occured and a list of Structures { count: int, Structures: Array[Structure] }
		var description_match_dictionary: Dictionary[int, Array] = {}
		var structure_array: Array[Structure]
		
		# Search through Rooms first as they might also come up if the parent Building name is searched
		for room: Room in room_array:
			if room.structure_name.to_lower() == searching_text:
				name_match_array.push_front(room)
			elif room.structure_name.containsn(searching_text):
				name_match_array.append(room)
			elif room.description.containsn(searching_text):
				var text_count: int = room.description.countn(searching_text)
				if not description_match_dictionary.has(text_count):
					var new_array: Array[Structure] = []
					description_match_dictionary[text_count] = new_array
				structure_array = description_match_dictionary[text_count]
				structure_array.append(room)
			elif room.lectures.containsn(searching_text):
				lecturers_match_array.append(room)
			elif room.get_parent_structure().structure_name.to_lower() == searching_text:
				name_match_array.push_front(room)
			elif room.get_parent_structure().structure_name.containsn(searching_text):
				name_match_array.push_front(room)
		
		for building: Building in building_array:
			if building.structure_name.to_lower() == searching_text:
				name_match_array.push_front(building)
			elif building.structure_name.containsn(searching_text):
				name_match_array.push_front(building)
			elif building.description.containsn(searching_text):
				var text_count: int = building.description.countn(searching_text)
				if not description_match_dictionary.has(text_count):
					var new_array: Array[Structure] = []
					description_match_dictionary[text_count] = new_array
				structure_array = description_match_dictionary[text_count]
				structure_array.append(building)
		
		var result_array: Array[Structure] = []
		result_array.append_array(name_match_array)
		result_array.append_array(lecturers_match_array)
		var counter_array: Array = description_match_dictionary.keys()
		counter_array.sort()
		counter_array.reverse()
		for counter: int in counter_array:
			structure_array = description_match_dictionary[counter]
			result_array.append_array(structure_array)
		
		return result_array
	# Short search - only look at Building letters
	elif searching_text.length() == 1:
		var location_match_array: Array[Structure] = []
		# Search through Buildings first so it is on top
		for building: Building in building_array:
			if building.building_letter.capitalize() == searching_text.capitalize():
				location_match_array.append(building)
				break
		
		for room: Room in room_array:
			if room.get_parent_structure().building_letter.capitalize() == searching_text.capitalize():
				location_match_array.append(room)
		
		return location_match_array
	
	return []


func set_up_search_items(search_text: String) -> void:
	var result_array: Array[Structure] = general_search(search_text)
	
	# Hide all items
	for search_item_h_box_container: SearchItemHBoxContainer in search_item_h_box_containers:
		search_item_h_box_container.visible = false
	for h_seperator: HSeparator in h_seperators:
		h_seperator.visible = false
	
	var index: int = 0
	var room: Room
	var building: Building
	var search_item_h_box_container: SearchItemHBoxContainer
	var h_seperator: HSeparator
	var _error: int
	for structure: Structure in result_array:
		# Only add new items if there are more search results
		if index >= len(search_item_h_box_containers):
			search_item_h_box_container = search_item_h_box_container_scene.instantiate()
			v_box_container.add_child(search_item_h_box_container)
			_error = search_item_h_box_container.connect("from_button_pressed", _on_search_item_h_box_container_from_button_pressed)
			_error = search_item_h_box_container.connect("to_button_pressed", _on_search_item_h_box_container_to_button_pressed)
			search_item_h_box_containers.append(search_item_h_box_container)
			h_seperator = HSeparator.new()
			v_box_container.add_child(h_seperator)
			h_seperators.append(h_seperator)
		else:
			search_item_h_box_container = search_item_h_box_containers[index]
			search_item_h_box_container.visible = true
			h_seperator = h_seperators[index]
			h_seperator.visible = true
			
		
		if structure is Room:
			room = structure as Room
			search_item_h_box_container.set_details(room, room.structure_name, room.get_parent_structure().structure_name, room.lectures)
		elif structure is Building:
			building = structure as Building
			search_item_h_box_container.set_details(building, building.structure_name, building.building_letter, building.description)
		
		index += 1


func _on_to_search_bar_line_edit_text_changed(new_text: String) -> void:
	top_search_bar_active = true
	set_up_search_items(new_text)


func _on_from_search_bar_line_edit_text_changed(new_text: String) -> void:
	top_search_bar_active = false
	set_up_search_items(new_text)


func _on_search_item_h_box_container_from_button_pressed(struct: Structure) -> void:
	set_from_search_structure.emit(struct)


func _on_search_item_h_box_container_to_button_pressed(struct: Structure) -> void:
	set_to_search_structure.emit(struct)
