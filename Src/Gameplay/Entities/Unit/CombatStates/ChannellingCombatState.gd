extends Node
class_name ChannellingCombatState

var state_name = "ChannellingCombatState"

var _target
var _ability : Ability
var _progress := 0.0
var _tick_progress := 0.0

signal channelling_started(ability)
signal channelling_progressed(ability, progress)
signal channelling_stopped(ability)


func _init(target, ability) -> void:
	_target = target
	_ability = ability
	_progress = ability.channel_duration


func on_enter(unit) -> void:
	unit.is_channelling = true
	unit.set_default_arms_animation_type(Enums.UnitAnimationType.CASTING)
	_connect_signals(unit)
	emit_signal("channelling_started", _ability)


func on_leave(unit) -> void:
	unit.is_channelling = false
	emit_signal("channelling_stopped", _ability)
	_disconnect_signals(unit)


func update(unit, delta: float):
	_progress -= delta
	_tick_progress += delta
	emit_signal("channelling_progressed", _ability, _progress)
	
	if _tick_progress >= _ability.tick_rate:
		if "channel_cost" in _ability && unit.current_mana < _ability.channel_cost:
			print("Insufficient mana for channel")
			return IdleCombatState.new()
			
		_ability._on_caster_channelling_ticked(_target, unit)
		_tick_progress = _tick_progress - _ability.tick_rate
	
	if _progress <= 0:
		return IdleCombatState.new()


func _connect_signals(unit) -> void:
	connect("channelling_started", unit, "_on_channelling_started")
	connect("channelling_progressed", unit, "_on_channelling_progressed")
	connect("channelling_stopped", unit, "_on_channelling_stopped")


func _disconnect_signals(unit) -> void:
	disconnect("channelling_started", unit, "_on_channelling_started")
	disconnect("channelling_progressed", unit, "_on_channelling_progressed")
	disconnect("channelling_stopped", unit, "_on_channelling_stopped")

