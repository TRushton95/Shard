extends Node
class_name ThreatData

var unit_id
var threat

func _init(unit_id, threat) -> void:
	self.unit_id = unit_id
	self.threat = threat
