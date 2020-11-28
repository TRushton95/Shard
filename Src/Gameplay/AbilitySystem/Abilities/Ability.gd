extends Node
class_name Ability

signal cooldown_started
signal cooldown_progressed
signal cooldown_ended


# Convention properties

export var cooldown := 0.0
var cooldown_timer : Timer

# End of  Convention properties


func _on_cooldown_timer_timeout() -> void:
	emit_signal("cooldown_ended")


func _ready() -> void:
	if cooldown > 0:
		cooldown_timer = Timer.new()
		cooldown_timer.one_shot = true
		add_child(cooldown_timer)
		cooldown_timer.connect("timeout", self, "_on_cooldown_timer_timeout") # TODO Does this call on superclass or only on this class?


func _process(delta: float) -> void:
	if cooldown_timer && cooldown_timer.time_left > 0:
		emit_signal("cooldown_progressed")


func try_start_cooldown() -> void:
	if cooldown_timer:
		print("test inner")
		cooldown_timer.start(cooldown)
		emit_signal("cooldown_started")
