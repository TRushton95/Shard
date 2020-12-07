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
var queued_ability_data : Array
var team := -1

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
signal casting_started(ability_name, duration)
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


func _on_CastTimer_timeout(ability: Ability, target) -> void:
	stop_casting()
	execute_ability(ability, target)
	
	if ability.cooldown > 0:
		ability.try_start_cooldown(ability.cooldown)


func _on_FollowPathingTimer_timeout() -> void:
	emit_signal("follow_path_outdated")


func _on_status_expired(status_effect) -> void:
	remove_status_effect(status_effect.name)


func _on_ChannelStopwatch_tick(ability: Ability) -> void:
	if "channel_cost" in ability:
		if current_mana < ability.channel_cost:
			print("Insufficient mana to continue channel")
			stop_channelling()
			return
		else:
			_set_current_mana(current_mana - ability.channel_cost)
			
	emit_signal("channelling_ticked")


func _on_ChannelStopwatch_timeout() -> void:
	stop_channelling()


func _on_AutoAttackTimer_timeout():
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
	$CastTimer.one_shot = false
	$FollowPathingTimer.one_shot = true
	$AutoAttackTimer.one_shot = true


func _process(delta: float) -> void:
#	if casting_index == -1 && channelling_index == -1:
	_move_along_path(delta)
		
	if casting_index >= 0:
		emit_signal("casting_progressed", $CastTimer.wait_time - $CastTimer.time_left)
	elif channelling_index >= 0:
		emit_signal("channelling_progressed", $ChannelStopwatch.get_time_remaining())
		
	if $AutoAttackTimer.time_left > 0:
		emit_signal("auto_attack_cooldown_progressed", $AutoAttackTimer.time_left)

remotesync func set_movement_path(movement_path: PoolVector2Array) -> void:
	_movement_path = movement_path
	if !is_moving():
		emit_signal("path_finished")


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
	if casting_index >= 0:
		print("Interrupted cast")
		stop_casting()
		
	if channelling_index >= 0:
		print("Interrupted channel")
		stop_channelling()


remotesync func stop_pursuing() -> void:
	queued_ability_data = []
	auto_attack_enabled = false
	$FollowPathingTimer.stop()


func auto_attack(target: Unit) -> void:
	if get_tree().is_network_server():
		target.rpc("damage", attack_power_attr.value, name)


func cast(ability: Ability, target) -> void:
	if casting_index >= 0:
		print("Already casting")
		return
	
	if ability.is_on_cooldown():
		print("Cannot cast ability while it is on cooldown")
		return
	
	if "toggled" in ability && ability.toggled && ability.active:
		ability.deactivate()
		return
	
	if "cost" in ability && current_mana < ability.cost:
		print("Insufficient mana to cast")
		return
		
	if channelling_index >= 0:
		stop_channelling()
		
	if "cast_time" in ability && ability.cast_time > 0:
		$CastTimer.connect("timeout", self, "_on_CastTimer_timeout", [ability, target])
		$CastTimer.start(ability.cast_time)
		casting_index = ability.get_index()
		emit_signal("casting_started", ability.name, ability.cast_time)
		
		if !ability.off_global_cooldown:
			for a in get_node("Abilities").get_children():
				if !a.off_global_cooldown:
					a.try_start_cooldown(Constants.GLOBAL_COOLDOWN)
	else:
		execute_ability(ability, target)
		
		if !ability.off_global_cooldown:
			for a in get_node("Abilities").get_children():
				if a == ability:
					var cooldown = a.cooldown if a.cooldown > Constants.GLOBAL_COOLDOWN else Constants.GLOBAL_COOLDOWN
					a.try_start_cooldown(cooldown)
				else:
					if !a.off_global_cooldown:
						a.try_start_cooldown(Constants.GLOBAL_COOLDOWN)


func stop_casting() -> void:
	if casting_index == -1:
		print("Unit is not casting")
		return
		
	var ability = get_node("Abilities").get_child(casting_index)
	
	print("Stopping cast")
	casting_index = -1
	$CastTimer.stop()
	$CastTimer.disconnect("timeout", self, "_on_CastTimer_timeout")
	emit_signal("casting_stopped", ability.name)


func channel(ability: Ability) -> void:
	if casting_index >= 0 || channelling_index >= 0:
		print("Already casting")
		
	if !"channel_duration" in ability || ability.channel_duration <= 0:
		print("Invalid channel_duration property on ability " + ability.Name)
			
	$ChannelStopwatch.setup(ability.channel_duration, ability.tick_rate)
	$ChannelStopwatch.connect("tick", self, "_on_ChannelStopwatch_tick", [ability])
	$ChannelStopwatch.connect("timeout", self, "_on_ChannelStopwatch_timeout")
	channelling_index = ability.get_index()
	emit_signal("channelling_started", ability.name, ability.channel_duration)
	
	$ChannelStopwatch.start()


func stop_channelling() -> void:
	if channelling_index == -1:
		print("Cannot stop channelling: unit is not channelling already")
		return
		
	print("Stopping channel")
	var ability = get_node("Abilities").get_child(channelling_index)
	channelling_index = -1
	$ChannelStopwatch.stop()
	$ChannelStopwatch.disconnect("tick", self, "_on_ChannelStopwatch_tick")
	$ChannelStopwatch.disconnect("timeout", self, "_on_ChannelStopwatch_timeout")
	emit_signal("channelling_stopped", ability.name)


func execute_ability(ability: Ability, target) -> void:
	if "cost" in ability && current_mana < ability.cost:
		print("Insufficient mana to execute")
		return
		
	ability.execute(target, self)
	
	if "cost" in ability:
		_set_current_mana(current_mana - ability.cost)
	
	if "channel_duration" in ability:
		channel(ability)


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
	return "Unit"


func _move_along_path(delta: float) -> void:
	if casting_index > -1 || channelling_index > -1:
		return
	
	var distance_to_walk = delta * movement_speed_attr.value
	
	while distance_to_walk > 0 && _movement_path.size() > 0:
		if queued_ability_data.size() == 2:
			var ability = get_node("Abilities").get_child(queued_ability_data[0])
			
			if ability.target_type == Enums.TargetType.Unit && position.distance_to(queued_ability_data[1].position) <= ability.cast_range:
				cast(ability, queued_ability_data[1])
				if team == queued_ability_data[1].team:
					set_movement_path([])
					stop_pursuing()
					
				queued_ability_data = []
								
				return
				
			elif ability.target_type == Enums.TargetType.Position && position.distance_to(queued_ability_data[1]) <= ability.cast_range:
				cast(ability, queued_ability_data[1])
				queued_ability_data = []
				set_movement_path([])
				return
				
		if focus && auto_attack_enabled && position.distance_to(focus.position) <= basic_attack_range:
			if $AutoAttackTimer.time_left == 0:
				print("auto attack timer at 0")
				auto_attack(focus)
				$AutoAttackTimer.start(auto_attack_speed)
				emit_signal("auto_attack_cooldown_started", auto_attack_speed)
			return
		
		var distance_to_next_point = position.distance_to(_movement_path[0])
		if distance_to_walk <= distance_to_next_point:
			position += position.direction_to(_movement_path[0]) * distance_to_walk
		else:
			position = _movement_path[0]
			_movement_path.remove(0)
			
		distance_to_walk -= distance_to_next_point
		
		if _movement_path.size() == 0:
			emit_signal("path_finished")


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
