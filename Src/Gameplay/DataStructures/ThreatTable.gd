extends Node
class_name ThreatTable

var threats := []


func add_threat(unit_id: int, threat: int) -> void:
	var threat_data = get_threat_data(unit_id)
	
	if threat_data:
		threat_data.threat += threat
	else:
		threat_data = ThreatData.new(unit_id, threat)
		threats.push_front(threat_data)
		
	threats.sort_custom(self, "sort_by_threat")
	print(str(threat_data.threat))


func remove_threat_data(unit_id: int) -> void:
	for i in range(threats.size()):
		if threats[i].unit_id == unit_id:
			threats.remove(i)
			break


func clear_threat_data() -> void:
	threats = []


func get_highest_threat_target() -> ThreatData:
	var result
	
	if threats.size() > 0:
		result = threats[0]
	
	return result


func get_threat_data(unit_id: int) -> ThreatData:
	var result
	
	for threat in threats:
		if threat.unit_id == unit_id:
			result = threat
	
	return result


func empty() -> bool:
	return threats.empty()


func sort_by_threat(a: ThreatData, b: ThreatData) -> bool:
	return a.threat < b.threat
