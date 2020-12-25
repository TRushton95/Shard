extends Node
class_name PursueState

var state_name = "PursueState"

var _movement_path : PoolVector2Array
var _target
var _distance := 0 # The distance the follow the target from
var _stop_on_reach := false

signal state_path_set(path)
signal state_path_finished


func _init(target, distance: int, stop_on_reach: bool) -> void:
	_target = target
	_distance = distance
	_stop_on_reach = stop_on_reach


func on_enter(unit) -> void:
	unit.is_moving = true
	_movement_path = NavigationHelper.get_simple_path(unit.position, _get_target_position())
	_connect_signals(unit)
	emit_signal("state_path_set", _movement_path)


func on_leave(unit) -> void:
	unit.is_moving = false
	_disconnect_signals(unit)


func update(unit, delta: float):
	if unit.casting_index > -1 || unit.channelling_index > -1:
		return
	
	var distance_to_walk = delta * unit.movement_speed_attr.value
	while distance_to_walk > 0 && _movement_path.size() > 0:
		if unit.position.distance_to(_get_target_position()) <= _distance:
			if _stop_on_reach:
				emit_signal("state_path_finished")
				return IdleNavigationState.new()
		
		distance_to_walk = _step_through_path(unit, distance_to_walk)
		
	return null


func _get_target_position() -> Vector2:
	return _target if _target is Vector2 else _target.position


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
			unit._play_animation(unit.AnimationType.WALKING, unit.direction)
	
	if _movement_path.size() == 0:
		emit_signal("state_path_finished")
		
	return distance_to_walk


func _connect_signals(unit) -> void:
	connect("state_path_set", unit, "_on_state_path_set")
	connect("state_path_finished", unit, "_on_state_path_finished")
	
	
func _disconnect_signals(unit) -> void:
	disconnect("state_path_set", unit, "_on_state_path_set")
	disconnect("state_path_finished", unit, "_on_state_path_finished")
