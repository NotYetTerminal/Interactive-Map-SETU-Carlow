extends Node
class_name RoomManager

# Contains { room_id: String, room: Room }
var _all_rooms: Dictionary[String, Room] = {}


func add_new_room(new_room: Room) -> void:
	_all_rooms[new_room.id] = new_room


func get_all_rooms() -> Array:
	return _all_rooms.values()


func _on_camera_3d_new_zoom_level(zoom_level: float) -> void:
	for room: Room in _all_rooms.values():
		room.set_icon_scale(zoom_level)
