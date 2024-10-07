# Script for waypoint for A* pathfinding
# Author: Gábor Major
# Date created: 2024-10-06
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
@export var from_waypoint: Waypoint


func _ready() -> void:
	own_coordinate = base_coordinate + position
	
