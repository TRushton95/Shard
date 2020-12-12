extends TextureRect

signal button_dropped_in_slot(action_button, slot)
signal button_dropped_on_button(dropped_button, target_button)


func _on_ButtonSlot_button_dropped_on_slot(action_button: ActionButton, slot: ButtonSlot) -> void:
	emit_signal("button_dropped_in_slot", action_button, slot)


func _on_ActionButton_button_dropped_on_button(dropped_button: ActionButton, target_button: ActionButton) -> void:
	emit_signal("button_dropped_on_button", dropped_button, target_button)


func _ready() -> void:
	for slot in $MarginContainer/HBoxContainer.get_children():
		slot.connect("button_dropped", self, "_on_ButtonSlot_button_dropped_on_slot", [slot])


func add_action_button(action_button: ActionButton) -> void:
	for slot in $MarginContainer/HBoxContainer.get_children():
		if slot.is_free():
			slot.add_button(action_button)
			action_button.connect("button_dropped", self, "_on_ActionButton_button_dropped_on_button", [action_button])
			return


func remove_action_button(index: int) -> void:
	var slot = $MarginContainer/HBoxContainer.get_child(index)
	var button = slot.pop_button()
	button.queue_free()


func move(from_index: int, to_index: int) -> void:
	var from_slot = $MarginContainer/HBoxContainer.get_child(from_index)
	var to_slot = $MarginContainer/HBoxContainer.get_child(to_index)
	
	if from_slot.is_free():
		print("No action at slot")
		return
		
	var from_button = from_slot.pop_button()
	
	var to_button = to_slot.pop_button()
	if to_button:
		from_slot.add_button(to_button)
		
	to_slot.add_button(from_button)


func get_button_index(action_button: ActionButton) -> int:
	var result = -1
	
	for slot in $MarginContainer/HBoxContainer.get_children():
		if slot.get_button() == action_button:
			result = slot.get_index()
			
	return result


func get_button(index: int) -> ButtonSlot:
	var result
	
	var slot = $MarginContainer/HBoxContainer.get_child(index)
	if !slot.is_free():
		result = slot.get_child(0)
		
	return result


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
