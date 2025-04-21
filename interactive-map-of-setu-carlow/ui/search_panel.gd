extends Panel
class_name SearchPanel

signal set_from_search_structure(structure: Structure)
signal set_to_search_structure(structure: Structure)
signal snap_to_structure(structure: Structure)

var building_manager: BuildingManager
var room_manager: RoomManager

@export var search_item_h_box_container_scene: PackedScene

@onready var search_button: Button = $VBoxContainer/VBoxContainer/HBoxContainer/SearchButton
@onready var bookmark_button: Button = $VBoxContainer/VBoxContainer/HBoxContainer/BookmarkButton

@onready var search_scroll_container: ScrollContainer = $VBoxContainer/SearchScrollContainer
@onready var search_v_box_container: VBoxContainer = $VBoxContainer/SearchScrollContainer/SearchVBoxContainer
@onready var bookmark_scroll_container: ScrollContainer = $VBoxContainer/BookmarkScrollContainer
@onready var bookmark_v_box_container: VBoxContainer = $VBoxContainer/BookmarkScrollContainer/BookmarkVBoxContainer

var search_item_h_box_containers: Array[SearchItemHBoxContainer] = []
var search_h_seperators: Array[HSeparator] = []

var bookmark_item_h_box_containers: Array[SearchItemHBoxContainer] = []
var bookmark_h_seperators: Array[HSeparator] = []
var bookmark_structure_ids: Array[String] = []


func set_managers(building_man: BuildingManager, room_man: RoomManager) -> void:
	building_manager = building_man
	room_manager = room_man


# Read in the bookmarks saved
func load_bookmarks() -> void:
	var file: FileAccess = FileAccess.open("user://bookmarks", FileAccess.READ)
	if file != null and file.get_length() != 0:
		bookmark_structure_ids = file.get_var()
		var bookmark_item_h_box_container: SearchItemHBoxContainer
		for structure_id: String in bookmark_structure_ids:
			bookmark_item_h_box_container = create_new_search_item(
				bookmark_item_h_box_containers,
				bookmark_h_seperators,
				bookmark_v_box_container,
				false
			)
			var structure: Structure = building_manager.get_building(structure_id)
			if structure == null:
				structure = room_manager.get_room(structure_id)
			set_search_item_details(bookmark_item_h_box_container, structure)


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
	for h_seperator: HSeparator in search_h_seperators:
		h_seperator.visible = false

	var index: int = 0
	var search_item_h_box_container: SearchItemHBoxContainer
	for structure: Structure in result_array:
		# Only add new items if there are more search results
		if index >= len(search_item_h_box_containers):
			search_item_h_box_container = create_new_search_item(
				search_item_h_box_containers,
				search_h_seperators,
				search_v_box_container,
				true
			)
		else:
			search_item_h_box_container = search_item_h_box_containers[index]
			search_item_h_box_container.visible = true
			search_h_seperators[index].visible = true

		search_item_h_box_container.bookmark_button.visible = not bookmark_structure_ids.has(structure.id)
		set_search_item_details(search_item_h_box_container, structure)
		index += 1


func create_new_search_item(
	item_h_box_containers: Array[SearchItemHBoxContainer],
	item_h_seperators: Array[HSeparator],
	item_v_box_container: VBoxContainer,
	add_icon: bool
) -> SearchItemHBoxContainer:
	var search_item_h_box_container: SearchItemHBoxContainer = search_item_h_box_container_scene.instantiate()
	item_v_box_container.add_child(search_item_h_box_container)

	var _error: int = search_item_h_box_container.connect("from_button_pressed", _on_search_item_h_box_container_from_button_pressed)
	_error = search_item_h_box_container.connect("to_button_pressed", _on_search_item_h_box_container_to_button_pressed)
	_error = search_item_h_box_container.connect("bookmark_button_pressed", _on_search_item_h_box_container_bookmark_button_pressed)
	_error = search_item_h_box_container.connect("structure_button_pressed", _on_search_item_h_box_container_structure_button_pressed)
	search_item_h_box_container.set_bookmark_button(add_icon)
	item_h_box_containers.append(search_item_h_box_container)

	var h_seperator: HSeparator = HSeparator.new()
	item_v_box_container.add_child(h_seperator)
	item_h_seperators.append(h_seperator)

	return search_item_h_box_container


func set_search_item_details(search_item_h_box_container: SearchItemHBoxContainer, structure: Structure) -> void:
	if structure is Room:
		var room: Room = structure as Room
		var extra_information: String
		if room.lectures.to_lower() == "none":
			extra_information = room.description
		else:
			extra_information = room.lectures + ". " + room.description
		var floor_string: String = " - "
		match room.floor_number:
			1:
				floor_string += "Ground Floor"
			2:
				floor_string += "First Floor"
			3:
				floor_string += "Second Floor"
		search_item_h_box_container.set_details(
			room,
			room.structure_name,
			room.get_parent_structure().structure_name + floor_string,
			extra_information
		)
	elif structure is Building:
		var building: Building = structure as Building
		search_item_h_box_container.set_details(building, building.structure_name, building.building_letter, building.description)
	else:
		print(structure)


func _on_to_search_bar_line_edit_text_changed(new_text: String) -> void:
	set_up_search_items(new_text)


func _on_from_search_bar_line_edit_text_changed(new_text: String) -> void:
	set_up_search_items(new_text)


func _on_search_item_h_box_container_from_button_pressed(struct: Structure) -> void:
	set_from_search_structure.emit(struct)


func _on_search_item_h_box_container_to_button_pressed(struct: Structure) -> void:
	set_to_search_structure.emit(struct)


func _on_search_item_h_box_container_bookmark_button_pressed(search_item_h_box_container: SearchItemHBoxContainer) -> void:
	if search_scroll_container.visible:
		search_item_h_box_container.set_bookmark_button(false)
		move_search_item_over(
			search_item_h_box_container,
			search_item_h_box_containers,
			search_h_seperators,
			search_v_box_container,
			bookmark_item_h_box_containers,
			bookmark_h_seperators,
			bookmark_v_box_container
		)
	else:
		search_item_h_box_container.set_bookmark_button(true)
		move_search_item_over(
			search_item_h_box_container,
			bookmark_item_h_box_containers,
			bookmark_h_seperators,
			bookmark_v_box_container,
			search_item_h_box_containers,
			search_h_seperators,
			search_v_box_container
		)

	var file: FileAccess = FileAccess.open("user://bookmarks", FileAccess.WRITE)
	if file != null and len(bookmark_structure_ids) != 0:
		var _error: bool = file.store_var(bookmark_structure_ids)


func move_search_item_over(
	search_item_h_box_container: SearchItemHBoxContainer,
	from_h_box_containers: Array[SearchItemHBoxContainer],
	from_h_seperators: Array[HSeparator],
	from_v_box_container: VBoxContainer,
	to_h_box_containers: Array[SearchItemHBoxContainer],
	to_h_seperators: Array[HSeparator],
	to_v_box_container: VBoxContainer
) -> void:
	var index: int = from_h_box_containers.find(search_item_h_box_container)
	from_h_box_containers.erase(search_item_h_box_container)
	from_v_box_container.remove_child(search_item_h_box_container)
	var h_seperator: HSeparator = from_h_seperators.pop_at(index)
	from_v_box_container.remove_child(h_seperator)

	to_h_box_containers.append(search_item_h_box_container)
	to_v_box_container.add_child(search_item_h_box_container)
	h_seperator = HSeparator.new()
	to_h_seperators.append(h_seperator)
	to_v_box_container.add_child(h_seperator)

	if bookmark_structure_ids.has(search_item_h_box_container.structure.id):
		bookmark_structure_ids.erase(search_item_h_box_container.structure.id)
	else:
		bookmark_structure_ids.append(search_item_h_box_container.structure.id)


func _on_search_item_h_box_container_structure_button_pressed(structure: Structure) -> void:
	snap_to_structure.emit(structure)


func _on_search_button_button_down() -> void:
	search_button.disabled = true
	search_scroll_container.visible = true

	bookmark_button.button_pressed = false
	bookmark_button.disabled = false
	bookmark_scroll_container.visible = false


func _on_bookmark_button_button_down() -> void:
	bookmark_button.disabled = true
	bookmark_scroll_container.visible = true

	search_button.button_pressed = false
	search_button.disabled = false
	search_scroll_container.visible = false
