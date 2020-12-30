extends Node
class_name StopCommand


# No type: cyclical reference
func execute(unit) -> void:
	if unit.is_casting || unit.is_channelling:
		unit.interrupt()
	if unit.is_moving:
		unit.stop_moving()
