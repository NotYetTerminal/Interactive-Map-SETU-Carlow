extends Control

@onready var to_search_bar_line_edit: LineEdit = $ToSearchBarPanel/ToSearchBarHSplitContainer/ToSearchBarLineEdit
@onready var from_search_bar_line_edit: LineEdit = $FromSearchBarPanel/FromSearchBarHSplitContainer/FromSearchBarLineEdit
@onready var from_search_bar_panel: Panel = $FromSearchBarPanel
@onready var h_flow_container: HFlowContainer = $ThirdHBoxContainer/HFlowContainer


func _ready() -> void:
	var os_name: String = OS.get_name()
	if os_name == "Android" or (os_name == "Web" and OS.has_feature("web_android")):
		h_flow_container.size_flags_horizontal = Control.SIZE_FILL


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


func _on_user_ui_root_cancel_navigation() -> void:
		from_search_bar_line_edit.text = ""
		to_search_bar_line_edit.text = ""
