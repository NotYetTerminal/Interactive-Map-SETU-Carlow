# Script for implementing A* pathfinding
# Author: Gábor Major
# Date created: 2024-10-06
extends Node3D

@export var starting_waypoint: Waypoint
@export var end_waypoint: Waypoint

func a_star_pathfinding() -> bool:
	var remaining_waypoints_list: Array[Waypoint] = [starting_waypoint]
	var checked_waypoints_list: Array[Waypoint] = []
	
	var current: Waypoint
	while len(remaining_waypoints_list) != 0:
		current = remaining_waypoints_list[0]
		for waypoint: Waypoint in remaining_waypoints_list:
			if waypoint.f_cost < current.f_cost or (
				waypoint.f_cost == current.f_cost and
				waypoint.h_cost < current.h_cost
			):
				current = waypoint
		
		print("\nChecking " + current.name)
		if current == end_waypoint:
			return true
		
		remaining_waypoints_list.erase(current)
		checked_waypoints_list.append(current)
		
		for neighbour: Waypoint in current.neighour_waypoints_list:
			if neighbour in checked_waypoints_list:
				continue
			
			print("Neighour: " + neighbour.name)
			
			var new_waypoint: bool = neighbour not in remaining_waypoints_list
			var new_distance_to_neighbour: float = (
				current.g_cost +
				current.own_coordinate.distance_to(neighbour.own_coordinate)
			)
			
			if new_waypoint or new_distance_to_neighbour < neighbour.g_cost:
				neighbour.g_cost = new_distance_to_neighbour
				neighbour.from_waypoint = current
				
				if new_waypoint:
					neighbour.h_cost = neighbour.own_coordinate.distance_to(end_waypoint.own_coordinate)
					remaining_waypoints_list.append(neighbour)
				
				print("F Cost: " + str(neighbour.f_cost))
				print("G Cost: " + str(neighbour.g_cost))
				print("H Cost: " + str(neighbour.h_cost))
	
	return false

func _ready() -> void:
	print(a_star_pathfinding())
