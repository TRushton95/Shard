extends Node
class_name IdleNavigationState

var state_name = "IdleNavigationState"


func on_enter(unit) -> void:
	if !unit.is_casting:
		unit.set_default_arms_animation_type(Enums.UnitAnimationType.IDLE)
		
	unit.set_default_torso_animation_type(Enums.UnitAnimationType.IDLE)
