extends Control

signal spawn_specific_structure(parent: Structure, structure_type: int)
signal cancel_navigation()
signal start_navigation(from_structure: Structure, to_structure: Structure, allow_stairs: bool)
signal update_floor_number(floor_number: int)
signal zoom_in_button()
signal zoom_out_button()

@onready var admin_ui_root: AdminUIRoot = $AdminUIRoot
@onready var user_ui_root: UserUIRoot = $UserUIRoot


func _on_admin_ui_root_spawn_specific_structure(parent: Structure, structure_type: int) -> void:
	spawn_specific_structure.emit(parent, structure_type)


func _on_user_ui_root_cancel_navigation() -> void:
	cancel_navigation.emit()


func _on_user_ui_root_start_navigation(from_structure: Structure, to_structure: Structure, allow_stairs: bool) -> void:
	start_navigation.emit(from_structure, to_structure, allow_stairs)


func _on_screen_elements_control_update_floor_number(floor_number: int) -> void:
	update_floor_number.emit(floor_number)


func _on_zoom_in_button_button_down() -> void:
	zoom_in_button.emit()


func _on_zoom_out_button_button_down() -> void:
	zoom_out_button.emit()


func _on_firebase_connector_admin_logged_in() -> void:
	admin_ui_root.admin_logged_in()


func _on_structure_spawner_select_spawned_structure(structure: Structure) -> void:
	admin_ui_root.select_structure(structure)


func _on_pathfinder_pathfinding_distance(distance: float) -> void:
	user_ui_root.pathfinding_distance(distance)


func _on_camera_3d_select_structure(selected_structure: Structure) -> void:
	admin_ui_root.select_structure(selected_structure)
	user_ui_root.select_structure(selected_structure)
