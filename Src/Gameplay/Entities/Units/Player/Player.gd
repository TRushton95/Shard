extends Unit
class_name Player

var default_torso_animation_type = Enums.UnitAnimationType.IDLE
var default_arms_animation_type = Enums.UnitAnimationType.IDLE
var playing_priority_arms_animation := false
var playing_priority_torso_animation := false


func _on_state_entered(state_name: String) -> void:
	match state_name:
		Constants.StateNames.IDLE_NAVIGATION:
			set_default_torso_animation_type(Enums.UnitAnimationType.IDLE)
			if !is_casting && !is_channelling:
				set_default_arms_animation_type(Enums.UnitAnimationType.IDLE)
				
		Constants.StateNames.MOVEMENT_NAVIGATION:
			set_default_torso_animation_type(Enums.UnitAnimationType.WALKING)
			set_default_arms_animation_type(Enums.UnitAnimationType.WALKING)
			
		Constants.StateNames.PURSUE_NAVIGATION:
			set_default_torso_animation_type(Enums.UnitAnimationType.WALKING)
			
		Constants.StateNames.CHANNELLING_COMBAT:
			set_default_arms_animation_type(Enums.UnitAnimationType.CASTING)
			
		Constants.StateNames.IDLE_COMBAT:
			if is_moving:
				set_default_arms_animation_type(Enums.UnitAnimationType.WALKING)
			else:
				set_default_arms_animation_type(Enums.UnitAnimationType.IDLE)


func _on_casting_started(ability: Ability) -> void:
	._on_casting_started(ability)
	
	if ability.cast_time > 0:
		set_default_arms_animation_type(Enums.UnitAnimationType.CASTING)
	elif !"channel_time" in ability:
		var casting_animation = _get_animation_name(Enums.UnitAnimationType.CASTING, direction)
		play_priority_arms_animation(casting_animation)


func _on_ArmsAnimationPlayer_animation_finished(anim_name: String):
	playing_priority_arms_animation = false
	var default_animation = _get_animation_name(default_arms_animation_type, direction)
	$ArmsSprite/AnimationPlayer.play(default_animation)
	
	# Sync up with body animation
	var body_animation_position = $TorsoSprite/AnimationPlayer.current_animation_position
	$ArmsSprite/AnimationPlayer.seek(body_animation_position, true)


func _on_TorsoAnimationPlayer_animation_finished(anim_name: String):
	playing_priority_torso_animation = false
	var default_animation = _get_animation_name(default_torso_animation_type, direction)
	$TorsoSprite/AnimationPlayer.play(default_animation)
	
	# Sync up with arms animation
	var arms_animation_position = $ArmsSprite/AnimationPlayer.current_animation_position
	$TorsoSprite/AnimationPlayer.seek(arms_animation_position, true)


func _on_Player_died() -> void:
	if playing_priority_torso_animation:
		play_priority_torso_animation("dead")
		
	if playing_priority_arms_animation:
		play_priority_arms_animation("dead")
	
	set_default_torso_animation_type(Enums.UnitAnimationType.DEAD)
	set_default_arms_animation_type(Enums.UnitAnimationType.DEAD)


func _ready() -> void:
	# super class called by default
	set_default_torso_animation_type(Enums.UnitAnimationType.IDLE)
	set_default_arms_animation_type(Enums.UnitAnimationType.IDLE)
	
	$ArmsSprite/AnimationPlayer.connect("animation_finished", self, "_on_ArmsAnimationPlayer_animation_finished")
	$TorsoSprite/AnimationPlayer.connect("animation_finished", self, "_on_TorsoAnimationPlayer_animation_finished")


func change_direction(new_direction: int) -> void:
	.change_direction(new_direction)
	
	var direction_name = Direction.keys()[direction].to_lower() # FIXME: Do this properly
	
	var current_torso_animation_type = get_torso_animation_name().split("_")[0]
	var current_torso_animation_position = get_torso_animation_position()
	
	var full_torso_animation_name = current_torso_animation_type + "_" + direction_name
	$TorsoSprite/AnimationPlayer.play(full_torso_animation_name)
	$TorsoSprite/AnimationPlayer.seek(current_torso_animation_position, true)
	
	var current_arms_animation_type = get_arms_animation_name().split("_")[0]
	var current_arms_animation_position = get_arms_animation_position()
	
	var full_arms_animation_name = current_arms_animation_type + "_" + direction_name
	$ArmsSprite/AnimationPlayer.play(full_arms_animation_name)
	$ArmsSprite/AnimationPlayer.seek(current_arms_animation_position, true)


func get_arms_animation_name() -> String:
	return $ArmsSprite/AnimationPlayer.current_animation


func get_arms_animation_position() -> float:
	return $ArmsSprite/AnimationPlayer.current_animation_position


func get_torso_animation_name() -> String:
	return $TorsoSprite/AnimationPlayer.current_animation


func get_torso_animation_position() -> float:
	return $TorsoSprite/AnimationPlayer.current_animation_position


func _set_arms_animation_type_looping(animation_type: int, loop: bool) -> void:
	for value in Direction.values():
		var animation = _get_animation_name(animation_type, value)
		$ArmsSprite/AnimationPlayer.get_animation(animation).set_loop(loop)


func _set_torso_animation_type_looping(animation_type: int, loop: bool) -> void:
	for value in Direction.values():
		var default_animation = _get_animation_name(animation_type, value)
		$TorsoSprite/AnimationPlayer.get_animation(default_animation).set_loop(loop)


func set_default_arms_animation_type(anim_type) -> void:
	_set_arms_animation_type_looping(default_arms_animation_type, false)
	default_arms_animation_type = anim_type
	_set_arms_animation_type_looping(default_arms_animation_type, true)
	
	if !playing_priority_arms_animation:
		var default = _get_animation_name(default_arms_animation_type, direction)
		#FIXME: This seems to be playing the previous direction, direction not updated yet at this point?
		$ArmsSprite/AnimationPlayer.play(default)


func set_default_torso_animation_type(anim_type) -> void:
	_set_torso_animation_type_looping(default_torso_animation_type, false)
	default_torso_animation_type = anim_type
	_set_torso_animation_type_looping(default_torso_animation_type, true)
		
	if !playing_priority_torso_animation:
		var default = _get_animation_name(default_torso_animation_type, direction)
		$TorsoSprite/AnimationPlayer.play(default)


func play_priority_arms_animation(anim_name: String, position := 0.0) -> void:
	playing_priority_arms_animation = true
	$ArmsSprite/AnimationPlayer.play(anim_name)
	
	if position > 0.0:
		$ArmsSprite/AnimationPlayer.seek(position, true)


func play_priority_torso_animation(anim_name: String, position := 0.0) -> void:
	playing_priority_torso_animation = true
	$TorsoSprite/AnimationPlayer.play(anim_name)
	
	if position > 0.0:
		$TorsoSprite/AnimationPlayer.seek(position, true)


func _play_on_enter_casting_combat_animation(ability: Ability) -> void:
	if ability.cast_time > 0:
		set_default_arms_animation_type(Enums.UnitAnimationType.CASTING)
	elif !"channel_time" in ability:
		var casting_animation = _get_animation_name(Enums.UnitAnimationType.CASTING, direction)
		play_priority_arms_animation(casting_animation)
