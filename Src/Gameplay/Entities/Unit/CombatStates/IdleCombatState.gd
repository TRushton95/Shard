extends Node
class_name IdleCombatState

var state_name = "IdleCombatState"


func on_enter(unit) -> void:
	unit._play_animation(unit.AnimationType.IDLE, unit.direction)
