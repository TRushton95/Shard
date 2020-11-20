extends TextureRect

signal ability_button_pressed(ability)


func _on_ability_button_pressed(ability):
	emit_signal("ability_button_pressed", ability)


func setup_abilities(abilities: Array) -> void:
	var index = 0
	
	for ability in abilities:
		if "icon" in ability:
			var ability_button = $MarginContainer/HBoxContainer.get_node("Ability" + str(index + 1))
			ability_button.texture_normal = ability.icon
			ability_button.connect("pressed", self, "_on_ability_button_pressed", [ability])
			
		index += 1


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
