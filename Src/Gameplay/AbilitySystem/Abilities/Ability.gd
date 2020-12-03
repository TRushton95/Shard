extends Node
class_name Ability

signal cooldown_started(duration)
signal cooldown_progressed
signal cooldown_ended


# Convention properties

export var cooldown := 0.0
export var off_global_cooldown := false
export var cast_time := 0.0
export var cast_range := 0
export var cost := 0
export var icon : Texture
var target_type = Enums.TargetType.Unset # Must be set in code in each ability, not exported as it is not customisable
var target_team = -1 # Only relevent for target_type unit
var toggled := false
var _cooldown_timer : Timer

# End of Convention properties


func _on_cooldown_timer_timeout() -> void:
	emit_signal("cooldown_ended")


func _ready() -> void:
	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = true
	add_child(_cooldown_timer)
	_cooldown_timer.connect("timeout", self, "_on_cooldown_timer_timeout") # TODO Does this call on superclass or only on this class?


func _process(delta: float) -> void:
	if _cooldown_timer.time_left > 0:
		emit_signal("cooldown_progressed")


func try_start_cooldown(duration) -> void:
	if duration > 0 && duration > _cooldown_timer.time_left:
		_cooldown_timer.start(duration)
		emit_signal("cooldown_started", duration)


func get_remaining_cooldown() -> float:
	return _cooldown_timer.time_left


func is_on_cooldown() -> bool:
	return _cooldown_timer.time_left > 0
