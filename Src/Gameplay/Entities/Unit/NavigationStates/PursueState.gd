extends Node
class_name PursueState

var state_name = "PursueState"

var _target
var _distance := 0 # The distance the follow the target from
var _stop_on_reach := false


func _init(target, distance: int, stop_on_reach: bool) -> void:
	_target = target
	_distance = distance
	_stop_on_reach = stop_on_reach


func on_enter(unit) -> void:
	unit.set_movement_path(NavigationHelper.get_simple_path(unit.position, _get_target_position()))


func on_leave(unit) -> void:
	unit.set_movement_path([])


func update(unit, delta: float):
	if unit.casting_index > -1 || unit.channelling_index > -1:
		return
	
	var distance_to_walk = delta * unit.movement_speed_attr.value
	while distance_to_walk > 0 && unit._movement_path.size() > 0:
		if unit.position.distance_to(_get_target_position()) <= _distance:
			return IdleNavigationState.new() if _stop_on_reach else null
		
		distance_to_walk = unit._step_through_path(distance_to_walk)
		
	return null


func _get_target_position() -> Vector2:
	return _target if _target is Vector2 else _target.position
