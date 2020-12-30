extends Node
class_name CastingCombatState

var state_name = "CastingCombatState"

var _target
var _ability : Ability
var _progress := 0.0
var _cast := false

signal casting_started(ability)
signal casting_progressed(ability, duration)
signal casting_stopped(ability)


func _init(target, ability) -> void:
	_target = target
	_ability = ability
	_progress = 0


func on_enter(unit) -> void:
	if unit.position.distance_to(TargetHelper.get_target_position(_target)) <= _ability.cast_range:
		_start_cast(unit)


func on_leave(unit) -> void:
	unit.is_casting = false
	emit_signal("casting_stopped", _ability)
	_disconnect_signals(unit)


func update(unit, delta: float):
	# If ability has not yet been cast then player was out of range, check if player can cast yet
	if !_cast:
		if unit.position.distance_to(TargetHelper.get_target_position(_target)) <= _ability.cast_range:
			_start_cast(unit)
			
		return
		
	_progress += delta
	emit_signal("casting_progressed", _ability, _progress)
	
	if _progress >= _ability.cast_time:
		if "cost" in _ability && unit.current_mana < _ability.cost:
			print("Insufficient mana to execute")
			return
		
		_ability.execute(_target, unit)
		_start_ability_cooldown(unit)
		
		if "cost" in _ability:
			unit._set_current_mana(unit.current_mana - _ability.cost)
		
		if "channel_time" in _ability && _ability.channel_time > 0:
			return ChannellingCombatState.new(_target, _ability)
			
		return IdleCombatState.new()


func _start_cast(unit) -> void:
	_cast = true
	unit.is_casting = true
	
	if _ability.cast_time > 0:
		unit.set_default_arms_animation_type(Enums.UnitAnimationType.CASTING)
	elif !"channel_time" in _ability:
		var casting_animation = unit._get_animation_name(Enums.UnitAnimationType.CASTING, unit.direction)
		unit.play_priority_arms_animation(casting_animation)
	
	var target_position = TargetHelper.get_target_position(_target)
	unit.face_point(target_position)
	_start_global_cooldown(unit)
	_connect_signals(unit)
	
	emit_signal("casting_started", _ability)


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