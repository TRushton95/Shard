extends PanelContainer

signal ability_button_pressed(ability)


func _on_Icon_pressed(ability):
	emit_signal("ability_button_pressed", ability)


func setup(abilities: Array) -> void:
	var index = 0
	
	for ability in abilities:
		if "icon" in ability:
			var ability_button = $HBoxContainer.get_node("Ability" + str(index + 1))
			ability_button.get_node("Icon").texture_normal = ability.icon
			ability_button.get_node("Icon").connect("pressed", self, "_on_Icon_pressed", [ability])
			
		index += 1
