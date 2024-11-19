extends Camera2D

var last_position: Vector2 = Vector2.ZERO
var moving_camera: bool = false

var min_zoom: float = 0.5
var max_zoom: float = 5
var zoom_amount: float = 0.1
var zoom_level: float = 1

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var input_event: InputEventMouseButton = event as InputEventMouseButton
		# Activating dragging
		if input_event.button_index == MOUSE_BUTTON_RIGHT:
			if input_event.is_pressed():
				last_position = input_event.position
				moving_camera = true
			else:
				moving_camera = false
		# Zooming with the mouse
		elif input_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_level = min(zoom_level + zoom_amount, max_zoom)
			zoom = Vector2(zoom_level, zoom_level)
		elif input_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_level = max(zoom_level - zoom_amount, min_zoom)
			zoom = Vector2(zoom_level, zoom_level)
	
	# Dragging with the mouse
	elif event is InputEventMouseMotion && moving_camera:
		var input_event: InputEventMouseMotion = event as InputEventMouseMotion
		# Divide move amount about zoom level to correct movement
		position += (last_position - input_event.position) / zoom_level
		last_position = input_event.position
