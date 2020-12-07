extends Panel

var ability_button_scene = load("res://Gameplay/UI/AbilityButton/AbilityButton.tscn")


func add_item(icon: Texture) -> Node:
	var ability_button = ability_button_scene.instance()
	ability_button.set_icon(icon)
	
	for slot in $GridContainer.get_children():
		if slot.get_children().empty():
			slot.add_child(ability_button)
			
			return ability_button
	
	print("Inventory is full")
	return null


func remove_item(index: int) -> void:
	var slot = $GridContainer.get_child(index)
	
	for child in slot.get_children():
		child.queue_free()
