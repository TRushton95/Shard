extends PanelContainer

var DATA_EXPIRY_TIME = 1.0

signal data_expired


func _on_DataExpiryTimer_timeout() -> void:
	emit_signal("data_expired")


func _ready() -> void:
	$DataExpiryTimer.one_shot = false
	$DataExpiryTimer.start(DATA_EXPIRY_TIME)


func set_name(name: String) -> void:
	$VBoxContainer/Title.text = name


func set_data(threat_table: ThreatTable) -> void:
	for child in $VBoxContainer/Entries.get_children():
		$VBoxContainer/Entries.remove_child(child)
	
	var data = threat_table.get_data()
	
	for entry in data:
		var label = Label.new()
		var unit = instance_from_id(entry.unit_id)
		
		label.text = unit.name + ": " + str(entry.threat)
		$VBoxContainer/Entries.add_child(label)
