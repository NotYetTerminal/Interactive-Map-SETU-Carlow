extends Node
class_name RoomManager

# Contains { room_id: String: room: Room }
var _all_rooms: Dictionary = {}


func add_new_room(new_room: Room) -> void:
	_all_rooms[new_room.id] = new_room


func get_room(room_id: String) -> Room:
	return _all_rooms[room_id]


func get_all_rooms() -> Array:
	return _all_rooms.values()
