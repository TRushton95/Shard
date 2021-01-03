extends Node

var aggressive := false


# No type: cyclical reference
func update(unit) -> void:
	if !aggressive && !unit.threat_table.empty():
		var top_threat_data = unit.threat_table.get_highest_threat_target()
		unit.input_command(AttackCommand.new(instance_from_id(top_threat_data.unit_id)))
		aggressive = true
