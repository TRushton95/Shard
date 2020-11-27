extends TextureRect

var ability_button_scene = load("res://Gameplay/UI/AbilityButton/AbilityButton.tscn")


func setup_abilities(abilities: Array) -> void:
	for ability in abilities:
		add_ability(ability)


func add_ability(ability) -> Button:
	var ability_button = ability_button_scene.instance()
	ability_button.ability_name = ability.name
	$MarginContainer/HBoxContainer.add_child(ability_button)
	ability_button.set_icon(ability.icon)
	
	return ability_button


func remove_ability(index: int) -> void:
	var ability_button = $MarginContainer/HBoxContainer.get_child(index)
	ability_button.queue_free()


func get_buttons() -> Array:
	return $MarginContainer/HBoxContainer.get_children()


func set_max_health(max_health: int) -> void:
	$Health.max_value = max_health
	_set_health_label($Health.value, max_health)


func set_max_mana(max_mana: int) -> void:
	$Mana.max_value = max_mana
	_set_mana_label($Mana.value, max_mana)


func set_current_health(health: int) -> void:
	$Health.value = health
	_set_health_label(health, $Health.max_value)


func set_current_mana(mana: int) -> void:
	$Mana.value = mana
	_set_mana_label(mana, $Mana.max_value)


func _set_health_label(value: int, max_value: int) -> void:
	$Health/Label.text = str(value) + " / " + str(max_value)
	
	
func _set_mana_label(value: int, max_value: int) -> void:
	$Mana/Label.text = str(value) + " / " + str(max_value)
