extends TextureRect

var ability_button_scene = load("res://Gameplay/UI/AbilityButton/AbilityButton.tscn")


signal ability_button_pressed(ability)
signal ability_button_mouse_entered(ability)
signal ability_button_mouse_exited(ability)


func _on_ability_button_pressed(ability) -> void:
	emit_signal("ability_button_pressed", ability)


func _on_ability_mouse_entered(ability) -> void:
	emit_signal("ability_button_mouse_entered", ability)


func _on_ability_mouse_exited(ability) -> void:
	emit_signal("ability_button_mouse_exited", ability)


func setup_abilities(abilities: Array) -> void:
	var index = 0
	
	for ability in abilities:
		if "icon" in ability:
			var ability_button = ability_button_scene.instance()
			$MarginContainer/HBoxContainer.add_child(ability_button)
			ability_button.set_icon(ability.icon)
			ability_button.connect("pressed", self, "_on_ability_button_pressed", [ability])
			ability_button.connect("mouse_entered", self, "_on_ability_mouse_entered", [ability])
			ability_button.connect("mouse_exited", self, "_on_ability_mouse_exited", [ability])
			
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
