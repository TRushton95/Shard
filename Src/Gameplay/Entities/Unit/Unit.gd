extends KinematicBody2D
class_name Unit

var _movement_path : PoolVector2Array
var current_health : int setget _set_current_health
remotesync var current_mana : int setget _set_current_mana # Remove remotesync when test_mana_refill is removed
var casting_index := -1 # -1 for not casting
var channelling_index := -1 # -1 for not channeling
var focus : Unit
remotesync var auto_attack_enabled := false # Requires focus to be set to do anything
var basic_attack_range := 200
var auto_attack_speed := 1.0
var _is_basic_attack_ready := true
var queued_ability_data : Array
var team := -1
var direction := 0
var icon = load("res://Gameplay/Entities/Unit/elementalist_icon.png")
var is_moving := false
var is_casting := false
var is_channelling := false
var is_basic_attacking := false

var _navigation_state = IdleNavigationState.new()
var _combat_state = IdleCombatState.new()

enum State { IDLE, MOVING, PURSUING }
enum Direction { DOWN, LEFT, RIGHT, UP }
enum AnimationType { IDLE, WALKING, CASTING }

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
signal follow_path_outdated
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


func _on_FollowPathingTimer_timeout() -> void:
	emit_signal("follow_path_outdated")


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


func _on_Unit_path_finished() -> void:
	_play_animation(AnimationType.IDLE, direction)


func _on_Unit_casting_started(ability_name: String, duration: float) -> void:
	pass
#	var target_position = target if target is Vector2 else target.position
#	_play_animation(AnimationType.CASTING, _get_direction_to_point(target_position))


func _on_casting_started(duration) -> void:
	emit_signal("casting_started", "test_ability_name", duration)


func _on_casting_progressed(duration: float) -> void:
	emit_signal("casting_progressed", duration)


func _on_casting_stopped() -> void:
	emit_signal("casting_stopped", "test_ability_name")


func _on_channelling_started(duration) -> void:
	emit_signal("channelling_started", "test_channel_name", duration)


func _on_channelling_progressed(duration: float) -> void:
	emit_signal("channelling_progressed", duration)


func _on_channelling_stopped() -> void:
	emit_signal("channelling_stopped", "test_channel_name")


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
	$FollowPathingTimer.one_shot = true
	$AutoAttackTimer.one_shot = true
	
	$AnimationPlayer.play("idle_down")


func _process(delta: float) -> void:
	if _navigation_state.has_method("update"):
		var new_navigation_state = _navigation_state.update(self, delta)
		if new_navigation_state:
			switch_navigation_state(new_navigation_state)
			
	if _combat_state.has_method("update"):
		var new_combat_state = _combat_state.update(self, delta)
		if new_combat_state:
			switch_combat_state(new_combat_state)
		
		
#	if casting_index >= 0:
#		emit_signal("casting_progressed", $CastTimer.wait_time - $CastTimer.time_left)
#	elif channelling_index >= 0:
#		emit_signal("channelling_progressed", $ChannelStopwatch.get_time_remaining())
		
	if $AutoAttackTimer.time_left > 0:
		emit_signal("auto_attack_cooldown_progressed", $AutoAttackTimer.time_left)


func set_movement_path(movement_path: PoolVector2Array) -> void:
	_movement_path = movement_path
	if !is_moving():
		emit_signal("path_finished")
	else:
		_play_animation(AnimationType.WALKING, direction)
		
	emit_signal("path_set", _movement_path)


func is_moving() -> bool:
	return _movement_path && _movement_path.size() > 0


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
		
#	if casting_index >= 0:
#		print("Interrupted cast")
#		stop_cast()
#
#	if channelling_index >= 0:
#		print("Interrupted channel")
#		stop_channelling()


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
	var angle = rad2deg(angle_rads)
	
	if angle > 45 && angle <= 135:
		result = Direction.UP
	elif angle > 135 || angle <= -135:
		result = Direction.RIGHT
	elif angle > -135 && angle <= -45:
		result = Direction.DOWN
	elif angle > -45 && angle <= 45:
		result = Direction.LEFT
			
	return result


func _play_animation(animation_type: int, current_direction: int) -> void:
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
		AnimationType.IDLE:
			animation_name = "idle"
		AnimationType.WALKING:
			animation_name = "walking"
		AnimationType.CASTING:
			animation_name = "casting"
			
	var full_animation_name = animation_name + direction_suffix
	var has_animation = $AnimationPlayer.has_animation(full_animation_name)
	
	if has_animation:
		$AnimationPlayer.play(full_animation_name)
	else:
		print("Cannot find animation:" + full_animation_name)


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

func move_to_point(point: Vector2) -> void:
	if is_casting || is_channelling:
		print("Interrupted")
		switch_combat_state(IdleCombatState.new())
		
	if is_basic_attacking:
		switch_combat_state(IdleCombatState.new())
		
	switch_navigation_state(MovementState.new(point))


func stop_moving() -> void:
	switch_navigation_state(IdleNavigationState.new())
	switch_combat_state(IdleCombatState.new())


func attack_target(target: Unit) -> void:
	switch_combat_state(AttackingCombatState.new(target))
	switch_navigation_state(PursueState.new(target, basic_attack_range, false))


func cast(ability: Ability, target) -> void:
	var target_position = target if target is Vector2 else target.position
	
	switch_combat_state(CastingCombatState.new(target, ability))
	if position.distance_to(target_position) > ability.cast_range:
		switch_navigation_state(PursueState.new(target, ability.cast_range, true))
	else:
		switch_navigation_state(IdleNavigationState.new())


func stop_cast() -> void:
	if casting_index == -1:
		print("Unit is not casting")
		return
		
	var ability = get_node("Abilities").get_child(casting_index)
	
	print("Stopping cast")
	casting_index = -1
	emit_signal("casting_stopped", ability.name)


#func _start_cast(ability: Ability, target) -> void:
#	if casting_index >= 0:
#		print("Already casting")
#		return
#
#	if ability.is_on_cooldown():
#		print("Cannot cast ability while it is on cooldown")
#		return
#
#	if "toggled" in ability && ability.toggled && ability.active:
#		ability.deactivate()
#		return
#
#	if "cost" in ability && current_mana < ability.cost:
#		print("Insufficient mana to cast")
#		return
#
##	if channelling_index > -1:
##		stop_channelling()
#
#	if "cast_time" in ability && ability.cast_time > 0:
#		$CastTimer.connect("timeout", self, "_on_CastTimer_timeout", [ability, target])
#		$CastTimer.start(ability.cast_time)
#		casting_index = ability.get_index()
#		emit_signal("casting_started", ability.name, ability.cast_time) # FIXME: Weird stupid fucking error here about incorrect parameter count when target is added as param
#
#		if !ability.off_global_cooldown:
#			for a in get_node("Abilities").get_children():
#				if !a.off_global_cooldown:
#					a.try_start_cooldown(Constants.GLOBAL_COOLDOWN)
#	else:
#		execute_ability(ability, target)
#
#		if !ability.off_global_cooldown:
#			for a in get_node("Abilities").get_children():
#				if a == ability:
#					var cooldown = a.cooldown if a.cooldown > Constants.GLOBAL_COOLDOWN else Constants.GLOBAL_COOLDOWN
#					a.try_start_cooldown(cooldown)
#				else:
#					if !a.off_global_cooldown:
#						a.try_start_cooldown(Constants.GLOBAL_COOLDOWN)


func switch_navigation_state(new_state) -> void:
	if !new_state:
		print("No new navigation state provided")
		
	print("Navigation state switch: " + _navigation_state.state_name + " -> " + new_state.state_name)
		
	if _navigation_state.has_method("on_leave"):
		_navigation_state.on_leave(self)
		
	_navigation_state = new_state
	
	if _navigation_state.has_method("on_enter"):
		_navigation_state.on_enter(self)


func switch_combat_state(new_state) -> void:
	if !new_state:
		print("No new combat state provided")
		
	print("Combat state switch: " + _combat_state.state_name + " -> " + new_state.state_name)
		
	if _combat_state.has_method("on_leave"):
		_combat_state.on_leave(self)
		
	_combat_state = new_state
	
	if _combat_state.has_method("on_enter"):
		_combat_state.on_enter(self)


#func _traverse_path(delta: float) -> void:
#	if casting_index > -1 || channelling_index > -1:
#		return
#
#	var distance_to_walk = delta * movement_speed_attr.value
#	while distance_to_walk > 0 && _movement_path.size() > 0:
#		distance_to_walk = _step_through_path(distance_to_walk)


func _step_through_path(distance_to_walk: int) -> int:
	var distance_to_next_point = position.distance_to(_movement_path[0])
	if distance_to_walk <= distance_to_next_point:
		position += position.direction_to(_movement_path[0]) * distance_to_walk
	else:
		position = _movement_path[0]
		_movement_path.remove(0)
		
	distance_to_walk -= distance_to_next_point
	
	if _movement_path.size() > 0:
		var new_direction = _get_direction_to_point(_movement_path[0])
		if new_direction > -1 && new_direction != direction:
			direction = new_direction
			_play_animation(AnimationType.WALKING, direction)
	
	if _movement_path.size() == 0:
		emit_signal("path_finished")
		
	return distance_to_walk


func basic_attack(target: Unit) -> void:
	if get_tree().is_network_server():
		target.rpc("damage", attack_power_attr.value, name)
		
	_is_basic_attack_ready = false
	$AutoAttackTimer.start(auto_attack_speed)
	emit_signal("auto_attack_cooldown_started", auto_attack_speed)
		

func is_basic_attack_off_cooldown() -> bool:
	return _is_basic_attack_ready
