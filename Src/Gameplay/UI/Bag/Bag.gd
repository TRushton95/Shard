extends TextureRect

signal button_dropped_in_slot(action_button, slot)
signal button_dropped_on_button(dropped_button, target_button)

var _held := false


func _on_GrabBox_button_down() -> void:
	_held = true


func _on_GrabBox_button_up() -> void:
	_held = false


func _on_CloseButton_pressed():
	hide()


func _on_ButtonSlot_button_dropped_on_slot(action_button: ActionButton, slot: ButtonSlot) -> void:
	emit_signal("button_dropped_in_slot", action_button, slot)


func _on_ActionButton_button_dropped_on_button(dropped_button: ActionButton, target_button: ActionButton) -> void:
	emit_signal("button_dropped_on_button", dropped_button, target_button)


func _input(event) -> void:
	if event is InputEventMouseMotion && _held:
		rect_position += event.relative


func _ready() -> void:
	for slot in $VBoxContainer/GridContainer.get_children():
		slot.connect("button_dropped", self, "_on_ButtonSlot_button_dropped_on_slot", [slot])


func get_button_index(action_button: ActionButton) -> int:
	var result = -1
	
	for slot in $VBoxContainer/GridContainer.get_children():
		if slot.get_button() == action_button:
			result = slot.get_index()
			
	return result


func add_action_button(action_button: ActionButton, index := -1) -> void:
	var success = false
	
	if index == -1:
		for slot in $VBoxContainer/GridContainer.get_children():
			if slot.is_free():
				slot.add_button(action_button)
				success = true
				
				return
				
		print(name + " is full")
	else:
		var slot = $VBoxContainer/GridContainer.get_child(index)
		
		if !slot:
			print("Cannot add action button to slot %s" % index)
			return
			
		slot.add_button(action_button)
		success = true
		
	if success:
		action_button.connect("button_dropped", self, "_on_ActionButton_button_dropped_on_button", [action_button])


func remove_action_button(index: int) -> void:
	var slot = $VBoxContainer/GridContainer.get_child(index)
	
	if !slot.is_free():
		var action_button = slot.pop_button()
		action_button.queue_free()


func move(from_index: int, to_index: int) -> void:
	var from_slot = $VBoxContainer/GridContainer.get_child(from_index)
	var to_slot = $VBoxContainer/GridContainer.get_child(to_index)
	
	if from_slot.is_free():
		print("No item at slot")
		return
		
	var from_button = from_slot.pop_button()
	
	var to_button = to_slot.pop_button()
	if to_button:
		from_slot.add_button(to_button)
		to_button.action_lookup.index = from_index
		
	to_slot.add_button(from_button)
	from_button.action_lookup.index = to_index
