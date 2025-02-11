extends CheckButton

signal edit_mode_toggled

# Toggle into admin mode
func _toggled(toggled_on: bool) -> void:
	if Globals.base_map != null:
		Globals.edit_mode = toggled_on
		Globals.base_map.enable_admin()
		edit_mode_toggled.emit()
