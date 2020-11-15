extends PanelContainer

var selected_unit : Unit


func set_profile(unit: Unit) -> void:
	selected_unit = unit
	update()


func update() -> void:
	$VBoxContainer/NameLabel.text = selected_unit.name
	$VBoxContainer/ResourceBar.set_max_value(selected_unit.max_health)
	$VBoxContainer/ResourceBar.set_current_value(selected_unit.current_health)
