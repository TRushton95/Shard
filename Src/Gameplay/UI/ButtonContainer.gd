extends PanelContainer
class_name ButtonContainer

signal button_dropped_in_slot(action_button, slot)
signal button_dropped_on_button(dropped_button, target_button)

export var enable_drag_and_drop := false
var _slots_container : Node


func _on_ButtonSlot_button_dropped_on_slot(action_button: ActionButton, slot: ButtonSlot) -> void:
	if _slots_container:
		emit_signal("button_dropped_in_slot", action_button, slot)


func _on_ActionButton_button_dropped_on_button(dropped_button: ActionButton, target_button: ActionButton) -> void:
	if enable_drag_and_drop:
		emit_signal("button_dropped_on_button", dropped_button, target_button)


func setup(name: String, slots_container: Node) -> void:
	self.name = name
	self._slots_container = slots_container
	self.enable_drag_and_drop = enable_drag_and_drop
	
	if enable_drag_and_drop:
		for slot in _slots_container.get_children():
			slot.connect("button_dropped", self, "_on_ButtonSlot_button_dropped_on_slot", [slot])


func get_button_index(action_button: ActionButton) -> int:
	var result = -1
	
	for slot in _slots_container.get_children():
		if slot.get_button() == action_button:
			result = slot.get_index()
			
	return result


func add_action_button(action_button: ActionButton) -> void:
	for slot in _slots_container.get_children():
		if slot.is_free():
			slot.add_button(action_button)
			
			if enable_drag_and_drop:
				action_button.connect("button_dropped", self, "_on_ActionButton_button_dropped_on_button", [action_button])
				
			return
	
	print(name + " is full")


func remove_action_button(index: int) -> void:
	var slot = _slots_container.get_child(index)
	
	if !slot.is_free():
		var action_button = slot.pop_button()
		action_button.queue_free()


func move(from_index: int, to_index: int) -> void:
	var from_slot = _slots_container.get_child(from_index)
	var to_slot = _slots_container.get_child(to_index)
	
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
