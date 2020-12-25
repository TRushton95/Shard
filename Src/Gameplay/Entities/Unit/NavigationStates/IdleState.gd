extends Node
class_name IdleNavigationState

var state_name = "IdleState"


func on_enter(unit) -> void:
	if !unit.is_casting && !unit.is_channelling:
		var animation = unit._get_animation_name(unit.AnimationType.IDLE, unit.direction)
		unit._play_animation(animation)
