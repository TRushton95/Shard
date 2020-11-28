extends Node
class_name Stopwatch

var duration: float
var tick_rate: float
var duration_timer : Timer
var tick_timer : Timer

signal timeout
signal tick


func _on_duration_timer_timeout():
	if tick_rate > 0.0:
		tick_timer.stop()
		
	emit_signal("timeout")


func _on_tick_timer_timeout():
	emit_signal("tick")


func _ready() -> void:
	#If multiple timers are started in the same frame, processing order is determined by node index
	if tick_rate > 0.0:
		tick_timer = Timer.new()
		add_child(tick_timer)
		tick_timer.connect("timeout", self, "_on_tick_timer_timeout")
	
	duration_timer = Timer.new()
	add_child(duration_timer)
	
	duration_timer.connect("timeout", self, "_on_duration_timer_timeout")


func setup(duration: float, tick_rate: float) -> void:
	self.duration = duration
	self.tick_rate = tick_rate


func start(initial_tick = false) -> void:
	duration_timer.one_shot = true
	duration_timer.start(duration)
	
	if tick_rate > 0.0:
		if initial_tick:
			_on_tick_timer_timeout()
		
		tick_timer.one_shot = false
		tick_timer.start(tick_rate)


func stop() -> void:
	duration_timer.stop()
	
	if tick_rate > 0.0:
		tick_timer.stop()


func get_time_remaining() -> float:
	return duration_timer.time_left
