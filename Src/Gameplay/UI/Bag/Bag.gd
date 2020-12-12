extends PanelContainer

var _held := false

signal button_dropped_in_slot(action_button, slot)


func _on_GrabBox_button_down() -> void:
	_held = true


func _on_GrabBox_button_up() -> void:
	_held = false


func _on_ButtonSlot_button_dropped(action_button: ActionButton, slot: ButtonSlot) -> void:
	emit_signal("button_dropped_in_slot", action_button, slot)


func _ready() -> void:
	for slot in $VBoxContainer/GridContainer.get_children():
		slot.connect("button_dropped", self, "_on_ButtonSlot_button_dropped", [slot])


func _input(event) -> void:
	if event is InputEventMouseMotion && _held:
		rect_position += event.relative


func add_action_button(action_button: ActionButton) -> void:
	for slot in $VBoxContainer/GridContainer.get_children():
		if slot.is_free():
			slot.add_button(action_button)
			return
	
	print("Bag is full")


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


func remove_action_button(index: int) -> void:
	var slot = $VBoxContainer/GridContainer.get_child(index)
	
	if !slot.is_free():
		var button = slot.pop_button()
		button.queue_free()
