extends ScrollContainer


func _ready() -> void:
	# Set the scroll bar to Black
	var v_scroll_bar: VScrollBar = get_v_scroll_bar()
	var scroll_style_box_flat: StyleBoxFlat = v_scroll_bar.get_theme_stylebox("scroll")
	scroll_style_box_flat.bg_color = Color.BLACK
	v_scroll_bar.add_theme_stylebox_override("scroll", scroll_style_box_flat)

	var h_scroll_bar: HScrollBar = get_h_scroll_bar()
	scroll_style_box_flat = h_scroll_bar.get_theme_stylebox("scroll")
	scroll_style_box_flat.bg_color = Color.BLACK
	h_scroll_bar.add_theme_stylebox_override("scroll", scroll_style_box_flat)
