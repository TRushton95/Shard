extends KinematicBody2D
class_name Unit

var _movement_path : PoolVector2Array
var speed := 250
var max_health := 100
var current_health := max_health setget _set_current_health
var max_mana := 20
var current_mana := max_mana setget _set_current_mana
var is_casting := false
var channelling_index := -1 # -1 for not channeling

signal left_clicked
signal path_finished
signal casting_started(ability_name, duration)
signal casting_progressed(time_elapsed)
signal casting_stopped
signal channelling_started(ability_name, duration)
signal channelling_progressed(time_remaining)
signal channelling_stopped
signal channelling_ticked()
signal damage_received(value)
signal healing_received(unit, value)


func _on_Clickbox_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton && event.pressed:
		if event.button_index == BUTTON_LEFT:
			emit_signal("left_clicked")


func _on_CastTimer_timeout(ability, target) -> void:
	stop_casting()
	execute_ability(ability, target)


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


func _set_current_health(value: int) -> void:
	current_health = value
	$UnitProfile/VBoxContainer/HealthBar.set_current_value(current_health)


func _set_current_mana(value: int) -> void:
	current_mana = value
	$UnitProfile/VBoxContainer/ManaBar.set_current_value(current_mana)


func _ready():
	$UnitProfile/VBoxContainer/HealthBar.initialise(current_health)
	$UnitProfile/VBoxContainer/ManaBar.initialise(current_mana)
	$CastTimer.one_shot = false


func _process(delta: float) -> void:
	if _movement_path && _movement_path.size() > 0:
		if is_casting:
			stop_casting()
		elif channelling_index >= 0:
			stop_channelling()
			
		_move_along_path(delta)
		
	if is_casting:
		emit_signal("casting_progressed", $CastTimer.wait_time - $CastTimer.time_left)
	elif channelling_index >= 0:
		emit_signal("channelling_progressed", $ChannelStopwatch.get_time_remaining())


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
	
	if new_health > max_health:
		new_health = max_health
		
	_set_current_health(new_health)
	
	print("%s received %s healing from %s" % [name, value, source_name])
	emit_signal("healing_received", value)


func cast(index: int, target) -> void:
	if is_casting:
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
		is_casting = true
		emit_signal("casting_started", ability.name, ability.cast_time)
	else:
		execute_ability(ability, target)


func stop_casting() -> void:
	if !is_casting:
		print("Unit is not casting")
		return
		
	print("Stopping cast")
	is_casting = false
	$CastTimer.stop()
	$CastTimer.disconnect("timeout", self, "_on_CastTimer_timeout")
	emit_signal("casting_stopped")


func channel(ability) -> void:
	if is_casting || channelling_index >= 0:
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
	
	$ChannelStopwatch.start(true)


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


func remove_status_effect(status_effect: Status) -> void:
	status_effect.queue_free()


func _move_along_path(delta: float) -> void:
	var distance_to_walk = delta * speed
	
	while distance_to_walk > 0 && _movement_path.size() > 0:
		var distance_to_next_point = position.distance_to(_movement_path[0])
		if distance_to_walk <= distance_to_next_point:
			position += position.direction_to(_movement_path[0]) * distance_to_walk
		else:
			position = _movement_path[0]
			_movement_path.remove(0)
			
		distance_to_walk -= distance_to_next_point
		
		if _movement_path.size() == 0:
			emit_signal("path_finished")
