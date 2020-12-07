extends Panel

var action_button_scene = load("res://Gameplay/UI/ActionButton/ActionButton.tscn")


func add_item(icon: Texture) -> Node:
	var action_button = action_button_scene.instance()
	action_button.set_icon(icon)
	
	for slot in $GridContainer.get_children():
		if slot.get_children().empty():
			slot.add_child(action_button)
			
			return action_button
	
	print("Inventory is full")
	return null


func remove_item(index: int) -> void:
	var slot = $GridContainer.get_child(index)
	
	for child in slot.get_children():
		child.queue_free()
