extends State
class_name PursueNavigationState

var _movement_path : PoolVector2Array
var _target
var _distance := 0 # The distance the follow the target from
var _stop_on_reach := false
var _path_update_time := 0.0
var _path_update_rate := 0.0

signal state_path_set(path)
signal state_path_removed


func _init(target, distance: int, stop_on_reach: bool) -> void:
	state_name = "PursueNavigationState"
	_target = target
	_distance = distance
	_stop_on_reach = stop_on_reach


func on_enter(unit) -> void:
	.on_enter(unit)
	unit.is_moving = true
	_movement_path = NavigationHelper.get_simple_path(unit.position, TargetHelper.get_target_position(_target))
	_path_update_rate = _get_path_update_rate(unit.position, TargetHelper.get_target_position(_target))
	emit_signal("state_path_set", _movement_path)


func on_leave(unit) -> void:
	unit.is_moving = false
	emit_signal("state_path_removed")
	.on_leave(unit)


func update(unit, delta: float):
	_path_update_time += delta
	if _path_update_time >= _path_update_rate:
		_movement_path = NavigationHelper.get_simple_path(unit.position, TargetHelper.get_target_position(_target))
		_path_update_time -= _path_update_rate
		emit_signal("state_path_set", _movement_path)
	
	var distance_to_walk = delta * unit.movement_speed_attr.value
	while distance_to_walk > 0 && _movement_path.size() > 0:
		if unit.position.distance_to(TargetHelper.get_target_position(_target)) <= _distance:
			if _stop_on_reach:
				return IdleNavigationState.new()
			else:
				return
		
		distance_to_walk = _step_through_path(unit, distance_to_walk)
		
	return null


func _get_path_update_rate(from: Vector2, to: Vector2) -> float:
	var UPDATE_CONST = 0.0004
	var update_rate = (UPDATE_CONST * from.distance_to(to)) + 0.2
	
	return update_rate


func _step_through_path(unit, distance_to_walk: int) -> int:
	var distance_to_next_point = unit.position.distance_to(_movement_path[0])
	if distance_to_walk <= distance_to_next_point:
		unit.position += unit.position.direction_to(_movement_path[0]) * distance_to_walk
	else:
		unit.position = _movement_path[0]
		_movement_path.remove(0)
		
	distance_to_walk -= distance_to_next_point
	
	if _movement_path.size() > 0:
		unit.face_point(_movement_path[0])
		
	return distance_to_walk


func _connect_signals(unit) -> void:
	._connect_signals(unit)
	connect("state_path_set", unit, "_on_state_path_set")
	connect("state_path_removed", unit, "_on_state_path_removed")
	
	
func _disconnect_signals(unit) -> void:
	._disconnect_signals(unit)
	disconnect("state_path_set", unit, "_on_state_path_set")
	disconnect("state_path_removed", unit, "_on_state_path_removed")
