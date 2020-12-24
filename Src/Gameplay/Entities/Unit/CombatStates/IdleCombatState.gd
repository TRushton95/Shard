extends Node
class_name IdleCombatState

var state_name = "IdleCombatState"


func on_enter(unit) -> void:
	if unit.is_moving:
		unit._play_animation(unit.AnimationType.WALKING, unit.direction)
	else:
		unit._play_animation(unit.AnimationType.IDLE, unit.direction)
