extends Control

@onready var to_search_bar_line_edit: LineEdit = $ToSearchBarPanel/ToSearchBarHSplitContainer/ToSearchBarLineEdit
@onready var from_search_bar_line_edit: LineEdit = $FromSearchBarPanel/FromSearchBarHSplitContainer/FromSearchBarLineEdit
@onready var from_search_bar_panel: Panel = $FromSearchBarPanel


func _on_user_ui_root__set_to_structure(to_structure: Structure) -> void:
	if to_structure is Room:
		to_search_bar_line_edit.text = (to_structure as Room).structure_name
	elif to_structure is Building:
		to_search_bar_line_edit.text = (to_structure as Building).structure_name
	else:
		to_search_bar_line_edit.text = ""


func _on_user_ui_root__set_from_structure(from_structure: Structure) -> void:
	if from_structure is Room:
		from_search_bar_line_edit.text = (from_structure as Room).structure_name
	elif from_structure is Building:
		from_search_bar_line_edit.text = (from_structure as Building).structure_name
	else:
		from_search_bar_line_edit.text = ""
