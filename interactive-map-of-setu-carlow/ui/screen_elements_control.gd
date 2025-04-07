extends Control

# Signals for outside nodes
signal update_floor_number()

@onready var floor_indicator_label: Label = $LeftControl/AspectRatioContainer3/FloorIndicatorLabel
@onready var floor_up_button: Button = $LeftControl/AspectRatioContainer/FloorUpButton
@onready var floor_down_button: Button = $LeftControl/AspectRatioContainer2/FloorDownButton

@onready var admin_check_button: CheckButton = $RightControl/AdminCheckButton
@onready var location_button: Button = $RightControl/AspectRatioContainer3/LocationButton

@export var ground_floor_theme: Theme
@export var first_floor_theme: Theme
@export var second_floor_theme: Theme

@export var normal_floor_changing_style_box_flat: StyleBoxFlat
@export var hover_floor_changing_style_box_flat: StyleBoxFlat
@export var pressed_floor_changing_style_box_flat: StyleBoxFlat

# Colours used for themeing the UI based on the current floor
@export var ground_level_normal_colour: Color
@export var ground_level_hover_colour: Color
@export var ground_level_pressed_colour: Color
@export var first_level_normal_colour: Color
@export var first_level_hover_colour: Color
@export var first_level_pressed_colour: Color
@export var second_level_normal_colour: Color
@export var second_level_hover_colour: Color
@export var second_level_pressed_colour: Color

# Used by floor indicator label
var floor_name_array: Array[String] = ["Ground Floor", "First Floor", "Second Floor"]
var floor_number: int = 1

# Make the edit mode button hidden for mobile
func _ready() -> void:
	var os_name: String = OS.get_name()
	if os_name == "Android" or (os_name == "Web" and OS.has_feature("web_android")):
		admin_check_button.visible = false
		if os_name == "Android":
			location_button.visible = true


func _on_floor_up_button_button_down() -> void:
	floor_number = min(floor_number + 1, 3)
	update_floor_label()
	update_theme()
	Globals.current_floor = floor_number
	update_floor_number.emit()


func _on_floor_down_button_button_down() -> void:
	floor_number = max(floor_number - 1, 1)
	update_floor_label()
	update_theme()
	Globals.current_floor = floor_number
	update_floor_number.emit()

# Update floor indicator label
func update_floor_label() -> void:
	floor_indicator_label.text = floor_name_array[floor_number - 1]


func update_theme() -> void:
	match floor_number:
		1:
			normal_floor_changing_style_box_flat.bg_color = ground_level_normal_colour
			hover_floor_changing_style_box_flat.bg_color = ground_level_hover_colour
			pressed_floor_changing_style_box_flat.bg_color = ground_level_pressed_colour
			floor_down_button.disabled = true
			floor_up_button.theme = first_floor_theme
		2:
			normal_floor_changing_style_box_flat.bg_color = first_level_normal_colour
			hover_floor_changing_style_box_flat.bg_color = first_level_hover_colour
			pressed_floor_changing_style_box_flat.bg_color = first_level_pressed_colour
			floor_up_button.disabled = false
			floor_down_button.disabled = false
			floor_up_button.theme = second_floor_theme
			floor_down_button.theme = ground_floor_theme
		3:
			normal_floor_changing_style_box_flat.bg_color = second_level_normal_colour
			hover_floor_changing_style_box_flat.bg_color = second_level_hover_colour
			pressed_floor_changing_style_box_flat.bg_color = second_level_pressed_colour
			floor_up_button.disabled = true
			floor_down_button.theme = first_floor_theme
