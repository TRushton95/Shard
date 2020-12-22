extends Node
class_name AutoAttackState

var state_name = "AutoAttackState"

var _target


func _on_unit_follow_path_outdated(unit) -> void:
	var M := 0.0004 # M in a linear equation to calculate the follow path invalidation time based on distance, may need fine tuning as gameplay emerges
	var PATH_INVALIDATE_TIME_MINIMUM := 0.2 # C in the linear equation
	var distance = unit.position.distance_to(_target.position)
	var invalidate_time = (M * distance) + PATH_INVALIDATE_TIME_MINIMUM # Time until path is next invalidated
	
	unit.set_movement_path(NavigationHelper.get_simple_path(unit.position, _target.position))
	unit.get_node("FollowPathingTimer").start(invalidate_time)


func _init(target) -> void:
	_target = target


func on_enter(unit) -> void:
	unit.get_node("FollowPathingTimer").start(1.0)
	unit.connect("follow_path_outdated", self, "_on_unit_follow_path_outdated", [unit])
	unit.set_movement_path(NavigationHelper.get_simple_path(unit.position, _target.position))


func on_leave(unit) -> void:
	unit.set_movement_path([])


func update(unit, delta: float):
	if unit.casting_index > -1 || unit.channelling_index > -1:
		return
	
	var target_position = _get_target_position()
	if unit.position.distance_to(target_position) <= unit.basic_attack_range:
		if unit.is_basic_attack_off_cooldown():
			unit.basic_attack(_target)
			
		return null
	
	var distance_to_walk = delta * unit.movement_speed_attr.value
	while distance_to_walk > 0 && unit._movement_path.size() > 0:
		distance_to_walk = unit._step_through_path(distance_to_walk)
		
	return null


func _get_target_position() -> Vector2:
	return _target if _target is Vector2 else _target.position
