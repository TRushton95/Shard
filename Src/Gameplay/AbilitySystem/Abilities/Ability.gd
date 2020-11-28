extends Node
class_name Ability

signal cooldown_started
signal cooldown_progressed
signal cooldown_ended


# Convention properties

export var cooldown := 0.0
var _cooldown_timer : Timer

# End of  Convention properties


func _on_cooldown_timer_timeout() -> void:
	emit_signal("cooldown_ended")


func _ready() -> void:
	if cooldown > 0:
		_cooldown_timer = Timer.new()
		_cooldown_timer.one_shot = true
		add_child(_cooldown_timer)
		_cooldown_timer.connect("timeout", self, "_on_cooldown_timer_timeout") # TODO Does this call on superclass or only on this class?


func _process(delta: float) -> void:
	if _cooldown_timer && _cooldown_timer.time_left > 0:
		emit_signal("cooldown_progressed")


func try_start_cooldown() -> void:
	if _cooldown_timer:
		_cooldown_timer.start(cooldown)
		emit_signal("cooldown_started")


func get_remaining_cooldown() -> float:
	return _cooldown_timer.time_left


func is_on_cooldown() -> bool:
	return _cooldown_timer.time_left > 0
