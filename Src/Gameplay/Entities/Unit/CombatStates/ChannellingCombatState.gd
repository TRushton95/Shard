extends Node
class_name ChannellingCombatState

var state_name = "ChannellingCombatState"

var _target
var _ability : Ability
var _progress := 0.0
var _tick_progress := 0.0

signal channelling_started(channel_time)
signal channelling_progressed(progress)
signal channelling_stopped


func _init(target, ability) -> void:
	_target = target
	_ability = ability
	_progress = ability.channel_duration


func on_enter(unit) -> void:
	unit.is_channelling = true
	_connect_signals(unit)
	emit_signal("channelling_started", _ability.channel_duration)


func on_leave(unit) -> void:
	unit.is_channelling = false
	emit_signal("channelling_stopped")
	_disconnect_signals(unit)


func update(unit, delta: float):
	_progress -= delta
	_tick_progress += delta
	emit_signal("channelling_progressed", _progress)
	
	if _tick_progress >= _ability.tick_rate:
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

