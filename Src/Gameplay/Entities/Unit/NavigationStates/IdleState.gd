extends Node
class_name IdleNavigationState

var state_name = "IdleState"


func on_enter(unit) -> void:
	if !unit.is_casting:
		unit.set_default_arms_animation(unit.AnimationType.IDLE)
		
	unit.set_default_torso_animation(unit.AnimationType.IDLE)
