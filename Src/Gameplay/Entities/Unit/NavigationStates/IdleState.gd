extends Node
class_name IdleNavigationState

var state_name = "IdleState"


func on_enter(unit) -> void:
	if !unit.is_casting && !unit.is_channelling:
		var animation = unit._get_animation_name(unit.AnimationType.IDLE, unit.direction)
#		unit._play_animation(animation)
		unit._play_torso_animation(animation)
		
		var current_anim_name = unit.get_arms_anim_player().current_animation
		var current_anim = unit.get_arms_anim_player().get_animation(current_anim_name)
		if current_anim.loop:
			unit.get_arms_anim_player().play(animation)
		else:
			unit.get_arms_anim_player().clear_queue()
			unit.get_arms_anim_player().queue(animation)
