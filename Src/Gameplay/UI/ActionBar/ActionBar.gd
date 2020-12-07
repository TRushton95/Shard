extends TextureRect

var action_button_scene = load("res://Gameplay/UI/ActionButton/ActionButton.tscn")


func add_action_button(action_name: String, action_icon: Texture) -> Button:
	var action_button = action_button_scene.instance()
	action_button.action_name = action_name
	$MarginContainer/HBoxContainer.add_child(action_button)
	action_button.set_icon(action_icon)
	
	return action_button


func remove_action(index: int) -> void:
	var action_button = $MarginContainer/HBoxContainer.get_child(index)
	action_button.queue_free()


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
