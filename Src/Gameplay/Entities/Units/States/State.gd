extends Node
class_name State

signal state_entered(state_name)

var state_name = ""


func on_enter(unit) -> void:
	_connect_signals(unit)
	emit_signal("state_entered", state_name)


func on_leave(unit) -> void:
	_disconnect_signals(unit)


func _connect_signals(unit) -> void:
	if unit.has_method("_on_state_entered"):
		connect("state_entered", unit, "_on_state_entered")


func _disconnect_signals(unit) -> void:
	if is_connected("state_entered", unit, "_on_state_entered"):
		disconnect("state_entered", unit, "_on_state_entered")
