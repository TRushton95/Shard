extends Node
class_name AttackCommand

var _target


func _init(target) -> void:
	_target = target

# No type: cyclical reference
func execute(unit) -> void:
	unit.attack_target(_target)
