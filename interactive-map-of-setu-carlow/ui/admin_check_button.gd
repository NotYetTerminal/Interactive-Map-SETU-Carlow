extends CheckButton

signal edit_mode_toggled

@onready var admin_ui_root: Control = $"../../UIRoot"
@onready var user_ui_root: Control = $"../../UserUIRoot"

# Toggle into admin mode
func _toggled(toggled_on: bool) -> void:
	Globals.edit_mode = toggled_on
	Globals.base_map.enable_admin()
	edit_mode_toggled.emit()
