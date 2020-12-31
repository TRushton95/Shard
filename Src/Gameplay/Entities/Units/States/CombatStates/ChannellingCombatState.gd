extends State
class_name ChannellingCombatState

var _target
var _ability : Ability
var _progress := 0.0
var _tick_progress := 0.0

signal channelling_started(ability)
signal channelling_progressed(ability, progress)
signal channelling_stopped(ability)


func _init(target, ability) -> void:
	state_name = "ChannellingCombatState"
	_target = target
	_ability = ability
	_progress = ability.channel_time


func on_enter(unit) -> void:
	.on_enter(unit)
	unit.is_channelling = true
	emit_signal("channelling_started", _ability)


func on_leave(unit) -> void:
	unit.is_channelling = false
	emit_signal("channelling_stopped", _ability)
	.on_leave(unit)


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
	._connect_signals(unit)
	connect("channelling_started", unit, "_on_channelling_started")
	connect("channelling_progressed", unit, "_on_channelling_progressed")
	connect("channelling_stopped", unit, "_on_channelling_stopped")


func _disconnect_signals(unit) -> void:
	._disconnect_signals(unit)
	disconnect("channelling_started", unit, "_on_channelling_started")
	disconnect("channelling_progressed", unit, "_on_channelling_progressed")
	disconnect("channelling_stopped", unit, "_on_channelling_stopped")

