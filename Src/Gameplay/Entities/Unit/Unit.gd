extends KinematicBody2D

var _path : PoolVector2Array
var speed := 250

signal path_finished

func _process(delta: float) -> void:
	if _path && _path.size() > 0:
		_move_along_path(delta)


remotesync func set_path(path: PoolVector2Array) -> void:
	_path = path


func _move_along_path(delta: float) -> void:
	var distance_to_walk = delta * speed
	
	while distance_to_walk > 0 && _path.size() > 0:
		var distance_to_next_point = position.distance_to(_path[0])
		if distance_to_walk <= distance_to_next_point:
			position += position.direction_to(_path[0]) * distance_to_walk
		else:
			position = _path[0]
			_path.remove(0)
			
		distance_to_walk -= distance_to_next_point
		
		if _path.size() == 0:
			emit_signal("path_finished")


