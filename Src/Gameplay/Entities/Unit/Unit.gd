extends KinematicBody2D
class_name Unit

var _path : PoolVector2Array
var speed := 250
var max_health:= 100
var current_health := max_health

signal left_clicked
signal path_finished


func _on_Clickbox_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton && event.pressed:
		if event.button_index == BUTTON_LEFT:
			emit_signal("left_clicked")


func _process(delta: float) -> void:
	if _path && _path.size() > 0:
		_move_along_path(delta)


remotesync func set_path(path: PoolVector2Array) -> void:
	_path = path


remotesync func damage(value: int, source_name: String) -> void:
	current_health -= value
	
	if current_health < 0:
		current_health = 0
	
	print("%s received %s damage from %s" % [name, value, source_name])


remotesync func heal(value: int, source_name: String) -> void:
	current_health += value
	
	if current_health > max_health:
		current_health = max_health
	
	print("%s received %s healing from %s" % [name, value, source_name])


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
