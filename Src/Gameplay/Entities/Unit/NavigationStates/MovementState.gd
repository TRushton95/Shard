extends Node
class_name MovementState

var state_name = "MovementState"

var _movement_path : PoolVector2Array
var _destination : Vector2
var _path_finished := false

signal state_path_set(path)
signal state_path_removed


func _init(destination: Vector2) -> void:
	_destination = destination


func on_enter(unit) -> void:
	unit.is_moving = true
	_movement_path = NavigationHelper.get_simple_path(unit.position, _destination)
	_connect_signals(unit)
	
	var animation = unit._get_animation_name(unit.AnimationType.WALKING, unit.direction)
	unit._play_animation(animation)
	
	emit_signal("state_path_set", _movement_path)


func on_leave(unit) -> void:
	unit.is_moving = false
	emit_signal("state_path_removed")
	_disconnect_signals(unit)


func update(unit, delta: float):
	if unit.casting_index > -1 || unit.channelling_index > -1:
		return
	
	var distance_to_walk = delta * unit.movement_speed_attr.value
	while distance_to_walk > 0 && _movement_path.size() > 0:
		distance_to_walk = _step_through_path(unit, distance_to_walk)
	
	if _movement_path.size() == 0:
		return IdleNavigationState.new()


func _step_through_path(unit, distance_to_walk: int) -> int:
	var distance_to_next_point = unit.position.distance_to(_movement_path[0])
	if distance_to_walk <= distance_to_next_point:
		unit.position += unit.position.direction_to(_movement_path[0]) * distance_to_walk
	else:
		unit.position = _movement_path[0]
		_movement_path.remove(0)
		
	distance_to_walk -= distance_to_next_point
	
	if _movement_path.size() > 0:
		var new_direction = unit._get_direction_to_point(_movement_path[0])
		if new_direction > -1 && new_direction != unit.direction:
			unit.direction = new_direction
			var animation = unit._get_animation_name(unit.AnimationType.WALKING, unit.direction)
			unit._play_animation(animation)
	
	return distance_to_walk


func _connect_signals(unit) -> void:
	connect("state_path_set", unit, "_on_state_path_set")
	connect("state_path_removed", unit, "_on_state_path_removed")
	
	
func _disconnect_signals(unit) -> void:
	disconnect("state_path_set", unit, "_on_state_path_set")
	disconnect("state_path_removed", unit, "_on_state_path_removed")
