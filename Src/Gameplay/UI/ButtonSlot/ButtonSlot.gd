extends ColorRect
class_name ButtonSlot

signal button_dropped(button)


func _on_ButtonSlot_mouse_entered():
	color = Color(1, 1, 1, 0.1)


func _on_ButtonSlot_mouse_exited():
	color = Color.transparent


func get_button() -> ActionButton:
	var result
	
	if get_child_count() > 0:
		result = get_child(0)
		
	return result


func add_button(button: ActionButton) -> void:
	if get_child_count() > 1:
		print("Slot already occupied")
		return
	
	add_child(button)


func pop_button() -> ActionButton:
	var result
	
	if get_child_count() == 0:
		return result
		
	var child = get_child(0)
	if child:
		result = child
		remove_child(child)
		
	return result


func is_free() -> bool:
	return get_child_count() == 0


func can_drop_data(position: Vector2, data) -> bool:
	var result
	
	if data.get_type() == "ActionButton":
		result = true
		
	return result


func drop_data(position: Vector2, data):
	if data.get_type() == "ActionButton":
		emit_signal("button_dropped", data)
