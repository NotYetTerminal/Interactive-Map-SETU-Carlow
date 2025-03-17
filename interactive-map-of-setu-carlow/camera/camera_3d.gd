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

var touch_points: Dictionary[int, Vector2] = {}
var start_distance: float = 0


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
	# Touch screen controls
	elif event is InputEventScreenTouch:
		var input_event: InputEventScreenTouch = event as InputEventScreenTouch
		if input_event.pressed:
			touch_points[input_event.index] = input_event.position
		else:
			var _exists: bool = touch_points.erase(input_event.index)
		
		if touch_points.size() == 1:
			start_distance = 0
			ray_cast_select(input_event)
		elif touch_points.size() == 2:
			var touch_point_positions: Array[Vector2] = touch_points.values()
			start_distance = touch_point_positions[0].distance_to(touch_point_positions[1])
		
	elif event is InputEventScreenDrag:
		var input_event: InputEventScreenDrag = event as InputEventScreenDrag
		touch_points[input_event.index] = input_event.position
		if touch_points.size() == 1:
			# Divide move amount by zoom level to correct movement
			position += Vector3(-input_event.screen_relative.x * move_speed, 0, input_event.screen_relative.y * move_speed) / (20 - zoom_level) * 5
		elif touch_points.size() == 2:
			var touch_point_positions: Array[Vector2] = touch_points.values()
			var current_distance: float =  touch_point_positions[0].distance_to(touch_point_positions[1])
			var zoom_factor: float = 1 - (start_distance / current_distance)
			if zoom_factor < 0:
				zoom_out(-(mouse_zoom_amount * zoom_factor))
			elif zoom_factor > 0:
				zoom_in(mouse_zoom_amount * zoom_factor)

# Ray cast to select an object on the map
func ray_cast_select(event: InputEvent) -> void:
	var input_position: Vector2
	if event is InputEventMouseButton:
		input_position = (event as InputEventMouseButton).position
	elif event is InputEventScreenTouch:
		input_position = (event as InputEventScreenTouch).position
	else:
		return
	var ray_length: float = 50
	var from: Vector3 = project_ray_origin(input_position)
	var to: Vector3 = from + project_ray_normal(input_position) * ray_length
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
		position = Vector3(structure.global_position.x, -10, structure.global_position.z + 3)
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
