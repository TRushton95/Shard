extends PanelContainer


func set_name(name: String) -> void:
	$VBoxContainer/HBoxContainer/HBoxContainer/NameLabel.text = name


func set_range(ability_range: int) -> void:
	$VBoxContainer/HBoxContainer/HBoxContainer/RangeLabel.text = str(ability_range)


func set_cost(cost: int) -> void:
	$VBoxContainer/CostLabel.text = str(cost)


func set_description(description: String) -> void:
	$VBoxContainer/DescriptionLabel.text = description
