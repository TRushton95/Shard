extends Node
class_name CastingCombatState

var state_name = "CastingCombatState"

var _target
var _ability : Ability
var _progress := 0.0
var _cast := false

signal casting_started(cast_time)
signal casting_progressed(progress)
signal casting_stopped


func _init(target, ability) -> void:
	_target = target
	_ability = ability
	_progress = 0


func on_enter(unit) -> void:
	var clean_target_position = _target if _target is Vector2 else _target.position
	if unit.position.distance_to(clean_target_position) <= _ability.cast_range:
		_start_cast(unit)
		


func on_leave(unit) -> void:
	unit.is_casting = false
	emit_signal("casting_stopped")
	_disconnect_signals(unit)


func update(unit, delta: float):
	# If ability has not yet been cast then player was out of range, check if player can cast yet
	if !_cast:
		var clean_target_position = _target if _target is Vector2 else _target.position
		if unit.position.distance_to(clean_target_position) <= _ability.cast_range:
			_start_cast(unit)
			
		return
		
	_progress += delta
	emit_signal("casting_progressed", _progress)
	
	if _progress >= _ability.cast_time:
		if "cost" in _ability && unit.current_mana < _ability.cost:
			print("Insufficient mana to execute")
			return
		
		_ability.execute(_target, unit)
		_start_ability_cooldown(unit)
		
		if "cost" in _ability:
			unit._set_current_mana(unit.current_mana - _ability.cost)
		
		if "channel_duration" in _ability && _ability.channel_duration > 0:
			return ChannellingCombatState.new(_target, _ability)
			
		return IdleCombatState.new()


func _start_cast(unit) -> void:
	_cast = true
	unit.is_casting = true
	_connect_signals(unit)
	emit_signal("casting_started", _ability.cast_time)
	
	_start_global_cooldown(unit)
	
	unit._play_animation(unit.AnimationType.CASTING, unit.direction)


func _start_global_cooldown(unit) -> void:
	if !_ability.off_global_cooldown:
		for a in unit.get_node("Abilities").get_children():
			if !a.off_global_cooldown:
				a.try_start_cooldown(Constants.GLOBAL_COOLDOWN)


func _start_ability_cooldown(unit) -> void:
	if !_ability.off_global_cooldown:
		for a in unit.get_node("Abilities").get_children():
			if a == _ability:
				var cooldown = a.cooldown if a.cooldown > Constants.GLOBAL_COOLDOWN else Constants.GLOBAL_COOLDOWN
				a.try_start_cooldown(cooldown)
			else:
				if !a.off_global_cooldown:
					a.try_start_cooldown(Constants.GLOBAL_COOLDOWN)


func _connect_signals(unit) -> void:
	connect("casting_started", unit, "_on_casting_started")
	connect("casting_progressed", unit, "_on_casting_progressed")
	connect("casting_stopped", unit, "_on_casting_stopped")


func _disconnect_signals(unit) -> void:
	disconnect("casting_started", unit, "_on_casting_started")
	disconnect("casting_progressed", unit, "_on_casting_progressed")
	disconnect("casting_stopped", unit, "_on_casting_stopped")
