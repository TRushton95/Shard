extends Node
class_name CastCommand

var _target
var _ability


# No type: cyclical reference
func _init(ability: Ability, target) -> void:
	_ability = ability
	_target = target
	

# No type: cyclical reference
func execute(unit) -> void:
	unit.cast(_ability, _target)
