extends Button

var start_message: String = "Start Navigation"
var cancel_message: String = "Cancel Navigation"


func _on_user_ui_root_cancel_navigation() -> void:
	text = start_message


func _on_user_ui_root_start_navigation(_from_structure: Structure, _to_structure: Structure, _allow_stairs: bool) -> void:
	text = cancel_message
