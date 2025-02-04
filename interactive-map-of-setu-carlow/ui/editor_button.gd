extends Button
class_name EditorButton

@export var new_texture: Texture2D
@export var delete_texture: Texture2D


func set_as_new_button() -> void:
	icon = new_texture


func set_as_delete_button() -> void:
	icon = delete_texture
