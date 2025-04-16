extends Control

@onready var to_search_bar_line_edit: LineEdit = $ToSearchBarPanel/ToSearchBarHSplitContainer/ToSearchBarLineEdit
@onready var from_search_bar_line_edit: LineEdit = $FromSearchBarPanel/FromSearchBarHSplitContainer/FromSearchBarLineEdit
@onready var h_flow_container: HFlowContainer = $ThirdHBoxContainer/HFlowContainer

@export var normal_from_style_box_flat: StyleBoxFlat
@export var normal_to_style_box_flat: StyleBoxFlat

var from_structure_in_search: Structure
var to_structure_in_search: Structure


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
	
	if to_structure != to_structure_in_search:
		normal_to_style_box_flat.bg_color = Color.WHITE
		var tween: Tween = create_tween()
		var _property_tweener: PropertyTweener = tween.tween_property(normal_to_style_box_flat, "bg_color", Color("ffcccc"), 0.5)
		to_structure_in_search = to_structure


func _on_user_ui_root__set_from_structure(from_structure: Structure) -> void:
	if from_structure is Room:
		from_search_bar_line_edit.text = (from_structure as Room).structure_name
	elif from_structure is Building:
		from_search_bar_line_edit.text = (from_structure as Building).structure_name
	else:
		from_search_bar_line_edit.text = ""
	
	if from_structure != from_structure_in_search:
		normal_from_style_box_flat.bg_color = Color.WHITE
		var tween: Tween = create_tween()
		var _property_tweener: PropertyTweener = tween.tween_property(normal_from_style_box_flat, "bg_color", Color("cbffb3"), 0.5)
		from_structure = from_structure_in_search


func _on_user_ui_root_cancel_navigation() -> void:
	_on_user_ui_root__set_to_structure(null)
	_on_user_ui_root__set_from_structure(null)
