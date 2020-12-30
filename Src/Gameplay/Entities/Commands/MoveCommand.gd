extends Node
class_name MoveCommand

var _target


func _init(target) -> void:
	_target = target

# No type: cyclical reference
func execute(unit) -> void:
	unit.move_to_point(_target)
