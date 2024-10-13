# Script for waypoint for A* pathfinding
# Author: Gábor Major
# Date modified: 2024-10-13
extends Node3D
class_name Waypoint

@export var base_coordinate: Vector3
@export var own_coordinate: Vector3

@export var f_cost: float:
	get:
		return g_cost + h_cost
@export var g_cost: float
@export var h_cost: float

@export var neighour_waypoints_list: Array[Waypoint]
@export var from_waypoint: Waypoint:
	set(value):
		from_waypoint = value
		rotate_arrow(value)


func _ready() -> void:
	own_coordinate = base_coordinate + position
	set_colour(Color.BLACK)


func set_colour(new_colour: Color) -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = new_colour
	var mesh_instance: MeshInstance3D = get_child(0)
	mesh_instance.set_surface_override_material(0, material)


func rotate_arrow(towards_node: Waypoint) -> void:
	var arrow_node: Node3D = get_node("Arrow")
	arrow_node.look_at(Vector3(towards_node.position.x, arrow_node.position.y,towards_node.position.z))
	arrow_node.show()


func found() -> void:
	set_colour(Color.BLUE)
	await get_tree().create_timer(1).timeout
	await from_waypoint.found()
