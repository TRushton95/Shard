extends KinematicBody2D
class_name Unit

var current_health : int setget _set_current_health
remotesync var current_mana : int setget _set_current_mana # Remove remotesync when test_mana_refill is removed
remotesync var auto_attack_enabled := false # Requires focus to be set to do anything
var basic_attack_range := 200
var auto_attack_speed := 1.0
var _is_basic_attack_ready := true
var team := -1
var direction := 0
var icon = load("res://Gameplay/Entities/Unit/elementalist_icon.png")
var is_moving := false
var is_casting := false
var is_channelling := false
var is_basic_attacking := false
var default_torso_animation_type = Enums.UnitAnimationType.IDLE
var default_arms_animation_type = Enums.UnitAnimationType.IDLE
var playing_priority_arms_animation := false
var playing_priority_torso_animation := false

var _navigation_state = IdleNavigationState.new()
var _combat_state = IdleCombatState.new()

enum State { IDLE, MOVING, PURSUING }
enum Direction { UP, DOWN, LEFT, RIGHT }

var base_movement_speed := 250
var base_health := 50
var base_mana := 25
var base_attack_power := 5
var base_spell_power := 0

var health_attr : ModifiableAttribute
var mana_attr : ModifiableAttribute
var attack_power_attr : ModifiableAttribute
var spell_power_attr : ModifiableAttribute
var movement_speed_attr : ModifiableAttribute

signal left_clicked
signal right_clicked
signal path_finished
signal path_set(path)
signal casting_started(ability_name, duration, target)
signal casting_progressed(time_elapsed)
signal casting_stopped(ability_name)
signal channelling_started(ability_name, duration)
signal channelling_progressed(time_remaining)
signal channelling_stopped(ability_name)
signal channelling_ticked
signal auto_attack_cooldown_started(duration)
signal auto_attack_cooldown_progressed(time_remaining)
signal auto_attack_cooldown_ended
signal ability_cooldown_started(ability)
signal ability_cooldown_progressed(ability)
signal ability_cooldown_ended(ability)
signal status_effect_applied(status_effect)
signal status_effect_removed(status_effect, index)
signal damage_received(value)
signal healing_received(value)
signal team_changed
signal mana_changed(value)
signal health_attr_changed(value)
signal mana_attr_changed(value)
signal attack_power_attr_changed(value)
signal spell_power_attr_changed(value)
signal movement_speed_attr_changed(value)


func _on_Clickbox_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton && event.pressed:
		if event.button_index == BUTTON_LEFT:
			emit_signal("left_clicked")
		if event.button_index == BUTTON_RIGHT:
			emit_signal("right_clicked")


func _on_status_expired(status_effect) -> void:
	remove_status_effect(status_effect.name)


func _on_AutoAttackTimer_timeout():
	_is_basic_attack_ready = true
	emit_signal("auto_attack_cooldown_ended")


# Stat change handlers

func _on_health_attr_changed(value: int) -> void:
	emit_signal("health_attr_changed", value)


func _on_mana_attr_changed(value: int) -> void:
	emit_signal("mana_attr_changed", value)


func _on_attack_power_attr_changed(value: int) -> void:
	emit_signal("attack_power_attr_changed", value)


func _on_spell_power_attr_changed(value: int) -> void:
	emit_signal("spell_power_attr_changed", value)


func _on_movement_speed_attr_changed(value: int) -> void:
	emit_signal("movement_speed_attr_changed", value)


func _on_ability_cooldown_started(duration: int, ability: Ability) -> void:
	emit_signal("ability_cooldown_started", ability, duration)


func _on_ability_cooldown_progressed(ability: Ability) -> void:
	emit_signal("ability_cooldown_progressed", ability)


func _on_ability_cooldown_ended(ability: Ability) -> void:
	emit_signal("ability_cooldown_ended", ability)


func _on_state_path_set(path: PoolVector2Array) -> void:
	emit_signal("path_set", path)


func _on_state_path_removed() -> void:
	emit_signal("path_finished")


func _on_casting_started(ability: Ability) -> void:
	emit_signal("casting_started", ability.name, ability.cast_time)


func _on_casting_progressed(ability: Ability, duration: float) -> void:
	emit_signal("casting_progressed", duration)


func _on_casting_stopped(ability: Ability) -> void:
	emit_signal("casting_stopped", ability.name)


func _on_channelling_started(ability: Ability) -> void:
	emit_signal("channelling_started", ability.name, ability.channel_time)


func _on_channelling_progressed(ability: Ability, duration: float) -> void:
	emit_signal("channelling_progressed", duration)


func _on_channelling_stopped(ability: Ability) -> void:
	emit_signal("channelling_stopped", "test_channel_name")


func _on_ArmsAnimationPlayer_animation_finished(anim_name):
	playing_priority_arms_animation = false
	var default_animation = _get_animation_name(default_arms_animation_type, direction)
	$ArmsSprite/AnimationPlayer.play(default_animation)
	
	# Sync up with body animation
	var body_animation_position = $TorsoSprite/AnimationPlayer.current_animation_position
	$ArmsSprite/AnimationPlayer.seek(body_animation_position, true)


func _on_TorsoAnimationPlayer_animation_finished(anim_name):
	playing_priority_torso_animation = false
	var default_animation = _get_animation_name(default_torso_animation_type, direction)
	$TorsoSprite/AnimationPlayer.play(default_animation)
	
	# Sync up with arms animation
	var arms_animation_position = $ArmsSprite/AnimationPlayer.current_animation_position
	$TorsoSprite/AnimationPlayer.seek(arms_animation_position, true)

# End of Stat change handlers


func _ready() -> void:
	health_attr = ModifiableAttribute.new(base_health)
	mana_attr = ModifiableAttribute.new(base_mana)
	attack_power_attr = ModifiableAttribute.new(base_attack_power)
	spell_power_attr = ModifiableAttribute.new(base_spell_power)
	movement_speed_attr = ModifiableAttribute.new(base_movement_speed)
	current_health = health_attr.value
	current_mana = mana_attr.value
	
	health_attr.connect("changed", self, "_on_health_attr_changed")
	mana_attr.connect("changed", self, "_on_mana_attr_changed")
	attack_power_attr.connect("changed", self, "_on_attack_power_attr_changed")
	spell_power_attr.connect("changed", self, "_on_spell_power_attr_changed")
	movement_speed_attr.connect("changed", self, "_on_movement_speed_attr_changed")
	
	for ability in get_node("Abilities").get_children():
		if ability.has_signal("cooldown_started"):
			ability.connect("cooldown_started", self, "_on_ability_cooldown_started", [ability])
			
		if ability.has_signal("cooldown_progressed"):
			ability.connect("cooldown_progressed", self, "_on_ability_cooldown_progressed", [ability])
		
		if ability.has_signal("cooldown_ended"):
			ability.connect("cooldown_ended", self, "_on_ability_cooldown_ended", [ability])
	
	$UnitProfile/VBoxContainer/SmallHealthBar.max_value = current_health
	$UnitProfile/VBoxContainer/SmallHealthBar.value = current_health
	$AutoAttackTimer.one_shot = true
	
	set_default_torso_animation_type(Enums.UnitAnimationType.IDLE)
	set_default_arms_animation_type(Enums.UnitAnimationType.IDLE)


func _process(delta: float) -> void:
	z_index = position.y
	
	if _navigation_state.has_method("update"):
		var new_navigation_state = _navigation_state.update(self, delta)
		if new_navigation_state:
			switch_navigation_state(new_navigation_state)
			
	if _combat_state.has_method("update"):
		var new_combat_state = _combat_state.update(self, delta)
		if new_combat_state:
			switch_combat_state(new_combat_state)
		
	if $AutoAttackTimer.time_left > 0:
		emit_signal("auto_attack_cooldown_progressed", $AutoAttackTimer.time_left)


remotesync func damage(value: int, source_name: String) -> void:
	var new_health = current_health - value
	
	if new_health < 0:
		new_health = 0
		
	_set_current_health(new_health)
	
	print("%s received %s damage from %s" % [name, value, source_name])
	emit_signal("damage_received", value)


remotesync func heal(value: int, source_name: String) -> void:
	var new_health = current_health + value
	
	if new_health > health_attr.value:
		new_health = health_attr.value
		
	_set_current_health(new_health)
	
	print("%s received %s healing from %s" % [name, value, source_name])
	emit_signal("healing_received", value)


remotesync func interrupt() -> void:
	if is_casting || is_channelling:
		print("Interrupted")
		switch_combat_state(IdleCombatState.new())


remotesync func push_status_effect(status_effect_data: Dictionary) -> void:
	var status_effect = StatusHelper.build_from_data(status_effect_data)
	
	# TODO: Assign uid from global uid helper class to allow for quicker type comparisons, this can be used in lots of other places for abilities too
	for existing_status_effect in $StatusEffects.get_children():
		if existing_status_effect.name == status_effect.name: 
			existing_status_effect.restart()
			return
			
	$StatusEffects.add_child(status_effect)
	status_effect.set_owner(self)
	status_effect.on_apply()
	status_effect.connect("expired", self, "_on_status_expired", [status_effect])
	emit_signal("status_effect_applied", status_effect)


# FIXME: If two zones overlap, exiting one will remove the status despite still being in the other
remotesync func remove_status_effect(status_effect_name: String) -> void:
	if !has_node("StatusEffects/" + status_effect_name):
		return
	
	var status_effect = get_node("StatusEffects/" + status_effect_name)
	status_effect.on_remove()
	var index = status_effect.get_index()
	$StatusEffects.remove_child(status_effect)
	emit_signal("status_effect_removed", status_effect, index)
	status_effect.queue_free()


# TODO: Debug method
func set_sprite_color(color: Color) -> void:
	$Sprite.modulate = color


func set_health_bar_color(color: Color) -> void:
	$UnitProfile/VBoxContainer/SmallHealthBar.modulate = color


func set_name(name: String) -> void:
	self.name = name
	$UnitProfile/VBoxContainer/NameLabel.text = name


func set_team(team: int) -> void:
	self.team = team
	emit_signal("team_changed")


func get_type() -> String:
	return Constants.ClassNames.UNIT


func _get_direction_to_point(point: Vector2) -> int:
	var result = -1
	
	var angle_rads = position.angle_to_point(point)
	var angle = stepify(rad2deg(angle_rads), 0.01) # Identical angles vary by extremely small margins, falling either side of direction breakpoints
	
	if angle > 45 && angle <= 135:
		result = Direction.UP
	elif angle > 135 || angle <= -135:
		result = Direction.RIGHT
	elif angle > -135 && angle <= -45:
		result = Direction.DOWN
	elif angle > -45 && angle <= 45:
		result = Direction.LEFT
	
	return result


func _get_animation_name(animation_type: int, current_direction: int) -> String:
	var direction_suffix = ""
	match current_direction:
		Direction.UP:
			direction_suffix = "_up"
		Direction.LEFT:
			direction_suffix = "_left"
		Direction.DOWN:
			direction_suffix = "_down"
		Direction.RIGHT:
			direction_suffix = "_right"
	
	var animation_name = ""
	match animation_type:
		Enums.UnitAnimationType.IDLE:
			animation_name = "idle"
		Enums.UnitAnimationType.WALKING:
			animation_name = "walking"
		Enums.UnitAnimationType.CASTING:
			animation_name = "casting"
	
	return animation_name + direction_suffix


func _set_current_health(value: int) -> void:
	current_health = value
	
	if current_health < 0:
		current_health = 0
	elif current_health > health_attr.value:
		current_health = health_attr.value
	$UnitProfile/VBoxContainer/SmallHealthBar.value = current_health


func _set_current_mana(value: int) -> void:
	current_mana = value
	
	if current_mana < 0:
		current_mana = 0
	elif current_mana > mana_attr.value:
		current_mana = mana_attr.value
	
	emit_signal("mana_changed", current_mana)

########################
# NEW API METHODS HERE #
########################

func input_command(command) -> void:
	if command.has_method("execute"):
		command.execute(self)


func move_to_point(point: Vector2) -> void:
	switch_navigation_state(MovementNavigationState.new(point))
	
	if is_casting || is_channelling:
		print("Interrupted")
		switch_combat_state(IdleCombatState.new())
		
	if is_basic_attacking:
		switch_combat_state(IdleCombatState.new())


func stop_moving() -> void:
	switch_navigation_state(IdleNavigationState.new())
	switch_combat_state(IdleCombatState.new())


func attack_target(target: Unit) -> void:
	switch_navigation_state(PursueNavigationState.new(target, basic_attack_range, false))
	switch_combat_state(AttackingCombatState.new(target))


func cast(ability: Ability, target) -> void:
	if !_is_team_target_valid(ability, target):
		print("Invalid target")
		return
		
	if ability.is_on_cooldown():
		print("Cannot cast ability while it is on cooldown")
		return
		
	if "cost" in ability && current_mana < ability.cost:
		print("Insufficient mana to cast")
		return
		
	if "toggled" in ability && ability.toggled && ability.active:
		ability.deactivate()
		return

	var target_position = TargetHelper.get_target_position(target)
	
	switch_combat_state(CastingCombatState.new(target, ability))
	if position.distance_to(target_position) > ability.cast_range:
		switch_navigation_state(PursueNavigationState.new(target, ability.cast_range, true))
	elif ability.cast_time > 0  || "channel_time" in ability:
		switch_navigation_state(IdleNavigationState.new())


func switch_navigation_state(new_state) -> void:
	if !new_state:
		print("No new navigation state provided")
		
#	print("Navigation state switch: " + _navigation_state.state_name + " -> " + new_state.state_name)
		
	if _navigation_state.has_method("on_leave"):
		_navigation_state.on_leave(self)
		
	_navigation_state = new_state
	
	if _navigation_state.has_method("on_enter"):
		_navigation_state.on_enter(self)


func switch_combat_state(new_state) -> void:
	if !new_state:
		print("No new combat state provided")
		
#	print("Combat state switch: " + _combat_state.state_name + " -> " + new_state.state_name)
		
	if _combat_state.has_method("on_leave"):
		_combat_state.on_leave(self)
		
	_combat_state = new_state
	
	if _combat_state.has_method("on_enter"):
		_combat_state.on_enter(self)


func basic_attack(target: Unit) -> void:
	if get_tree().is_network_server():
		target.rpc("damage", attack_power_attr.value, name)
		
	change_direction(_get_direction_to_point(target.position))
	_is_basic_attack_ready = false
	$AutoAttackTimer.start(auto_attack_speed)
	emit_signal("auto_attack_cooldown_started", auto_attack_speed)
		

func is_basic_attack_off_cooldown() -> bool:
	return _is_basic_attack_ready


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


func change_direction(new_direction: int) -> void:
	direction = new_direction
	
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


func face_point(point: Vector2) -> void:
	var new_direction = _get_direction_to_point(point)
	
	if new_direction != direction:
		change_direction(new_direction)


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


func _is_team_target_valid(ability: Ability, target) -> bool:
	# If ability targets a unit and the target is a unit of a different team to the ability target team
	return !(typeof(target) == TYPE_OBJECT && target.get_type() == "Unit" && ability.target_type == Enums.TargetType.Unit && ability.target_team != target.team)
