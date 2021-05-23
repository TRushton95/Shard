extends State
class_name CastingCombatState

var _target
var _ability : Ability
var _progress := 0.0
var _cast := false

signal casting_started(ability)
signal casting_progressed(ability, duration)
signal casting_stopped(ability)


func _init(target, ability) -> void:
	state_name = "CastingCombatState"
	_target = target
	_ability = ability
	_progress = 0


func on_enter(unit) -> void:
	.on_enter(unit)
	
	_cast = true
	unit.is_casting = true
	
	var target_position = TargetHelper.get_target_position(_target)
	unit.face_point(target_position)
	_start_global_cooldown(unit)
	
	emit_signal("casting_started", _ability)


func on_leave(unit) -> void:
	unit.is_casting = false
	emit_signal("casting_stopped", _ability)
	.on_leave(unit)


func update(unit, delta: float):
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
	._connect_signals(unit)
	connect("casting_started", unit, "_on_casting_started")
	connect("casting_progressed", unit, "_on_casting_progressed")
	connect("casting_stopped", unit, "_on_casting_stopped")


func _disconnect_signals(unit) -> void:
	._disconnect_signals(unit)
	disconnect("casting_started", unit, "_on_casting_started")
	disconnect("casting_progressed", unit, "_on_casting_progressed")
	disconnect("casting_stopped", unit, "_on_casting_stopped")
