extends Node

var target


# No type: cyclical reference
func update(unit) -> void:
	if unit.resetting:
		return
	
	var top_threat = unit.threat_table.get_highest_valid_threat()
	
	if !top_threat && target:
		target = null
		unit.reset()
		return
	
	if top_threat != target:
		target = top_threat
		unit.input_command(AttackCommand.new(instance_from_id(target.unit_id)))
