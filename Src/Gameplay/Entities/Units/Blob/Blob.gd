extends Unit
class_name Blob

var default_animation_type = Enums.UnitAnimationType.IDLE
var playing_priority_animation := false
var target # TODO: Remove once aggro table is added
var aggro_table := {}


func _on_Blob_damage_received(value: int, source_id: int, caster_id: int) -> void:
	if !aggro_table.has(caster_id):
		aggro_table[caster_id] = 1
	else:
		aggro_table[caster_id] = aggro_table[caster_id] + 1
		
	# TODO: debug remove me
	target = instance_from_id(caster_id)
	print("Threat changed due to damage received")


func _on_threat_unit_healed(value: int, source_id: int, caster_id: int, body_id: int) -> void:
	if !aggro_table.has(caster_id):
		aggro_table[caster_id] = 1
	else:
		aggro_table[caster_id] = aggro_table[caster_id] + 1
		
	# TODO: debug remove me
	target = instance_from_id(caster_id)
	print("Threat changed due to healing")


func _on_AggroArea_body_entered(body):
	if !body is Unit || body == self:
		return
		
	if aggro_table.size() == 0:
		var body_id = body.get_instance_id()
		aggro_table[body_id] = 1
		body.connect("healing_received", self, "_on_threat_unit_healed", [body_id])
		
	# TODO: debug remove me
		target = body


func _on_state_entered(state_name: String) -> void:
	match state_name:
		Constants.StateNames.IDLE_NAVIGATION:
			set_default_animation_type(Enums.UnitAnimationType.IDLE)
			
		Constants.StateNames.MOVEMENT_NAVIGATION:
			set_default_animation_type(Enums.UnitAnimationType.WALKING)
			
		Constants.StateNames.PURSUE_NAVIGATION:
			set_default_animation_type(Enums.UnitAnimationType.WALKING)


func _on_SpriteAnimationPlayer_animation_finished(anim_name: String) -> void:
	var default_animation = _get_animation_name(default_animation_type, get_parent().direction)
	$Sprite/AnimationPlayer.play(default_animation)


func _ready() -> void:
	# super class called by default
	set_default_animation_type(Enums.UnitAnimationType.IDLE)
	$Sprite/AnimationPlayer.connect("animation_finished", self, "_on_SpriteAnimationPlayer_animation_finished")


func change_direction(new_direction: int) -> void:
	.change_direction(new_direction)
	
	var direction_name = Direction.keys()[direction].to_lower() # FIXME: Do this properly
	
	var current_torso_animation_type = get_animation_name().split("_")[0]
	var current_torso_animation_position = get_animation_position()
	
	var full_torso_animation_name = current_torso_animation_type + "_" + direction_name
	$Sprite/AnimationPlayer.play(full_torso_animation_name)
	$Sprite/AnimationPlayer.seek(current_torso_animation_position, true)


func get_animation_name() -> String:
	return $Sprite/AnimationPlayer.current_animation


func get_animation_position() -> float:
	return $Sprite/AnimationPlayer.current_animation_position


func _set_animation_type_looping(animation_type: int, loop: bool) -> void:
	for value in Direction.values():
		var animation = _get_animation_name(animation_type, value)
		$Sprite/AnimationPlayer.get_animation(animation).set_loop(loop)


func set_default_animation_type(anim_type) -> void:
	_set_animation_type_looping(default_animation_type, false)
	default_animation_type = anim_type
	_set_animation_type_looping(default_animation_type, true)
		
	if !playing_priority_animation:
		var default = _get_animation_name(default_animation_type, direction)
		$Sprite/AnimationPlayer.play(default)


func play_priority_animation(anim_name: String, position := 0.0) -> void:
	playing_priority_animation = true
	$Sprite/AnimationPlayer.play(anim_name)
	
	if position > 0.0:
		$Sprite/AnimationPlayer.seek(position, true)