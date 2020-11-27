extends KinematicBody2D
class_name Unit

var _movement_path : PoolVector2Array
var current_health : int setget _set_current_health
remotesync var current_mana : int setget _set_current_mana # Remove remotesync when test_mana_refill is removed
var casting_index := -1 # -1 for not casting
var channelling_index := -1 # -1 for not channeling
remotesync var focus : Unit
var basic_attack_range := 200
var auto_attack_speed := 1.0

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
signal casting_stopped
signal channelling_started(ability_name, duration)
signal channelling_progressed(time_remaining)
signal channelling_stopped
signal channelling_ticked
signal auto_attack_cooldown_started(duration)
signal auto_attack_cooldown_progressed(time_remaining)
signal auto_attack_cooldown_ended
signal status_effect_applied(status_effect)
signal status_effect_removed(status_effect, index)
signal damage_received(value)
signal healing_received(value)
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


func _on_CastTimer_timeout(ability, target) -> void:
	stop_casting()
	execute_ability(ability, target)


func _on_FollowPathingTimer_timeout() -> void:
	emit_signal("follow_path_outdated")


func _on_status_expired(status_effect) -> void:
	remove_status_effect(status_effect)


func _on_ChannelStopwatch_tick(ability) -> void:
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

# End of Stat change handlers


func _ready():
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
	
	$UnitProfile/VBoxContainer/SmallHealthBar.max_value = current_health
	$UnitProfile/VBoxContainer/SmallHealthBar.value = current_health
	$CastTimer.one_shot = false
	$FollowPathingTimer.one_shot = true
	$AutoAttackTimer.one_shot = true


func _process(delta: float) -> void:
	if is_moving():
		if casting_index >= 0:
			stop_casting()
		elif channelling_index >= 0:
			stop_channelling()
			
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


func auto_attack(target: Unit) -> void:
	if get_tree().is_network_server():
		target.rpc("damage", attack_power_attr.value, name)


func cast(index: int, target) -> void:
	if casting_index >= 0:
		print("Already casting")
		return
		
	var ability = $Abilities.get_child(index)
	
	if "cost" in ability && current_mana < ability.cost:
		print("Insufficient mana to cast")
		return
		
	if channelling_index >= 0:
		stop_channelling()
		
	if "cast_time" in ability && ability.cast_time > 0:
		if is_moving():
			set_movement_path([])
			
		$CastTimer.connect("timeout", self, "_on_CastTimer_timeout", [ability, target])
		$CastTimer.start(ability.cast_time)
		casting_index = ability.get_index()
		emit_signal("casting_started", ability.name, ability.cast_time)
	else:
		execute_ability(ability, target)


func stop_casting() -> void:
	if casting_index == -1:
		print("Unit is not casting")
		return
		
	print("Stopping cast")
	casting_index = -1
	$CastTimer.stop()
	$CastTimer.disconnect("timeout", self, "_on_CastTimer_timeout")
	emit_signal("casting_stopped")


func channel(ability) -> void:
	if casting_index >= 0 || channelling_index >= 0:
		print("Already casting")
		
	if !"channel_duration" in ability || ability.channel_duration <= 0:
		print("Invalid channel_duration property on ability " + ability.Name)
		
	if is_moving():
		set_movement_path([])
			
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
	channelling_index = -1
	$ChannelStopwatch.stop()
	$ChannelStopwatch.disconnect("tick", self, "_on_ChannelStopwatch_tick")
	$ChannelStopwatch.disconnect("timeout", self, "_on_ChannelStopwatch_timeout")
	emit_signal("channelling_stopped")


func execute_ability(ability, target) -> void:
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
	
	$StatusEffects.add_child(status_effect)
	status_effect.set_owner(self)
	status_effect.connect("expired", self, "_on_status_expired", [status_effect])
	emit_signal("status_effect_applied", status_effect)


func remove_status_effect(status_effect: Status) -> void:
	var index = status_effect.get_index()
	$StatusEffects.remove_child(status_effect)
	emit_signal("status_effect_removed", status_effect, index)
	status_effect.queue_free()


func set_name(name: String) -> void:
	self.name = name
	$UnitProfile/VBoxContainer/NameLabel.text = name


func _move_along_path(delta: float) -> void:
	var distance_to_walk = delta * movement_speed_attr.value
	
	while distance_to_walk > 0 && _movement_path.size() > 0:
		if focus && position.distance_to(focus.position) <= basic_attack_range:
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
