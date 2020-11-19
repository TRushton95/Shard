extends PanelContainer


func set_name(value: String) -> void:
	$MarginContainer/VBoxContainer/NameLabel.text = value


func set_movement_speed(value: int) -> void:
	$MarginContainer/VBoxContainer/MovementSpeed/AttributeValue.text = value


func set_stamina(value: int) -> void:
	$MarginContainer/VBoxContainer/Stamina/AttributeValue.text = value


func set_spell_power(value: int) -> void:
	$MarginContainer/VBoxContainer/SpellPower/AttributeValue.text = value
