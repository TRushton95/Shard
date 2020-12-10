extends ColorRect


func _on_ButtonSlot_mouse_entered():
	color = Color(1, 1, 1, 0.1)


func _on_ButtonSlot_mouse_exited():
	color = Color.transparent


func add_button(button: ActionButton) -> void:
	if get_child_count() > 1:
		print("Slot already occupied")
		return
	
	add_child(button)


func pop_button() -> ActionButton:
	var result
	
	var child = get_child(0)
	if child:
		result = child
		remove_child(child)
		
	return result


func is_free() -> bool:
	return get_child_count() == 0
