extends KinematicBody2D

var path : PoolVector2Array
var speed := 250

signal path_finished

func _process(delta: float) -> void:
	if path && path.size() > 0:
		_move_along_path(delta)


func _move_along_path(delta: float) -> void:
	var distance_to_walk = delta * speed
	
	while distance_to_walk > 0 && path.size() > 0:
		var distance_to_next_point = position.distance_to(path[0])
		if distance_to_walk <= distance_to_next_point:
			position += position.direction_to(path[0]) * distance_to_walk
		else:
			position = path[0]
			path.remove(0)
			
		distance_to_walk -= distance_to_next_point
		
		if path.size() == 0:
			emit_signal("path_finished")
