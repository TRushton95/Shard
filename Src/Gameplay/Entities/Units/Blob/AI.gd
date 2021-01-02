extends Node

var aggressive := false


# No type: cyclical reference
func update(unit) -> void:
	if !aggressive && unit.target:
		unit.input_command(AttackCommand.new(unit.target))
		aggressive = true
