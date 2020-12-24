extends Node
class_name AbilityPursueState

var state_name = "AbilityPursueState"

var _queued_ability : Ability
var _target


func _init(queued_ability: Ability, target) -> void:
	_queued_ability = queued_ability
	_target = target


func on_enter(unit) -> void:
	unit.set_movement_path(NavigationHelper.get_simple_path(unit.position, _get_target_position()))


func on_leave(unit) -> void:
	unit.set_movement_path([])


func update(unit, delta: float):
	if unit.casting_index > -1 || unit.channelling_index > -1:
		return
	
	var distance_to_walk = delta * unit.movement_speed_attr.value
	while distance_to_walk > 0 && unit._movement_path.size() > 0:
		if unit.position.distance_to(_get_target_position()) <= _queued_ability.cast_range:
#			unit._start_cast(_queued_ability, _target)
			return IdleNavigationState.new()
		
		distance_to_walk = unit._step_through_path(distance_to_walk)
		
	return null


func _get_target_position() -> Vector2:
	return _target if _target is Vector2 else _target.position
