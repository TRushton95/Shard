extends Node
class_name IdleCombatState

var state_name = "IdleCombatState"


func on_enter(unit) -> void:
	if unit.is_moving:
		unit.set_default_arms_animation(unit.AnimationType.WALKING)
	else:
		unit.set_default_arms_animation(unit.AnimationType.IDLE)
