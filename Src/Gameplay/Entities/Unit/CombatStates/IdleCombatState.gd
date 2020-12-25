extends Node
class_name IdleCombatState

var state_name = "IdleCombatState"


func on_enter(unit) -> void:
	var animation
	if unit.is_moving:
		animation = unit._get_animation_name(unit.AnimationType.WALKING, unit.direction)
	else:
		animation = unit._get_animation_name(unit.AnimationType.IDLE, unit.direction)
	
	unit._play_animation(animation)
