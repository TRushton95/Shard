extends Node
class_name Status

var is_debuff : bool
var icon_texture_path: String
var duration : float
var tick_rate := 0.0
var tick_damage := 0
var tick_healing := 0

var stopwatch : Stopwatch

signal expired


func _on_stopwatch_tick():
	if tick_damage > 0:
		if get_tree().is_network_server():
			get_owner().rpc("damage", tick_damage, name)
	
	if tick_healing > 0:
		if get_tree().is_network_server():
			get_owner().rpc("heal", tick_healing, name)


func _on_stopwatch_timeout():
	emit_signal("expired")


func _init(is_debuff : float, duration : float, icon_texture_path: String) -> void:
	self.is_debuff = is_debuff
	self.duration = duration
	self.icon_texture_path = icon_texture_path


func _ready() -> void:
	if tick_rate > 0.0:
		stopwatch = Stopwatch.new()
		stopwatch.setup(duration, tick_rate)
		add_child(stopwatch)
		stopwatch.connect("tick", self, "_on_stopwatch_tick")
		stopwatch.connect("timeout", self, "_on_stopwatch_timeout")
		stopwatch.start()


func restart() -> void:
	if !stopwatch:
		print("Cannot restart uninitialised stopwatch")
		return
		
	stopwatch.start()


func get_time_remaining() -> float:
	return stopwatch.get_time_remaining()


func to_data() -> Dictionary:
	return {
		"name": name,
		"icon_texture_path": icon_texture_path,
		"is_debuff": is_debuff,
		"duration": duration,
		"tick_rate": tick_rate,
		"tick_damage": tick_damage,
		"tick_healing": tick_healing
	}
