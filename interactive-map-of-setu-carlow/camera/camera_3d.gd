extends Camera3D

# Currently selected structure
signal select_structure(selected_structure: Structure)

var moving_camera: bool = false
var screen_ratio: float

var min_zoom: float = 3
var max_zoom: float = 15
var mouse_zoom_amount: float = 0.2
var button_zoom_amount: float = 1
var zoom_level: float = 10

var move_speed: float = 0.01


func _ready() -> void:
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	screen_ratio = screen_size.y / screen_size.x


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var input_event: InputEventMouseButton = event as InputEventMouseButton
		# Activating dragging
		if input_event.button_index == MOUSE_BUTTON_RIGHT:
			if input_event.is_pressed():
				moving_camera = true
			else:
				moving_camera = false
		# Zooming with the mouse
		elif input_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in(mouse_zoom_amount)
		elif input_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out(mouse_zoom_amount)
		# Selecing
		elif input_event.button_index == MOUSE_BUTTON_LEFT:
			if input_event.is_pressed():
				ray_cast_select(input_event)
	# Dragging with the mouse
	elif event is InputEventMouseMotion && moving_camera:
		var input_event: InputEventMouseMotion = event as InputEventMouseMotion
		# Divide move amount by zoom level to correct movement
		position += Vector3(-input_event.relative.x * move_speed, 0, input_event.relative.y * move_speed) / (20 - zoom_level) * 10

# Ray cast to select an object on the map
func ray_cast_select(input_event: InputEventMouseButton) -> void:
	var ray_length: float = 50
	var from: Vector3 = project_ray_origin(input_event.position)
	var to: Vector3 = from + project_ray_normal(input_event.position) * ray_length
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	
	var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	ray_query.from = from
	ray_query.to = to
	var raycast_result: Dictionary = space.intersect_ray(ray_query)
	
	print()
	print(raycast_result)
	
	if raycast_result.has("collider") and raycast_result["collider"] is Structure:
		var structure: Structure = raycast_result["collider"]
		# Position the selected Structure in the middle
		position = Vector3(structure.global_position.x, -10, structure.global_position.z + 1)
		zoom_level = 9
		size = zoom_level
		select_structure.emit(structure)
	else:
		select_structure.emit(null)

# Used by mouse and zoom buttons
func zoom_in(zoom_amount: float) -> void:
	zoom_level = max(zoom_level - zoom_amount, min_zoom)
	size = zoom_level

# Used by mouse and zoom buttons
func zoom_out(zoom_amount: float) -> void:
	zoom_level = min(zoom_level + zoom_amount, max_zoom)
	size = zoom_level


func _on_ui_root_zoom_in_button() -> void:
	zoom_in(button_zoom_amount)


func _on_ui_root_zoom_out_button() -> void:
	zoom_out(button_zoom_amount)
