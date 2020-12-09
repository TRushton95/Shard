extends PanelContainer

var action_button_scene = load("res://Gameplay/UI/ActionButton/ActionButton.tscn")

var _held := false


func _on_GrabBox_button_down() -> void:
	_held = true


func _on_GrabBox_button_up() -> void:
	_held = false


func _input(event) -> void:
	if event is InputEventMouseMotion && _held:
		rect_position += event.relative


func add_item(icon: Texture) -> Node:
	var action_button = action_button_scene.instance()
	action_button.set_icon(icon)
	
	for slot in $VBoxContainer/GridContainer.get_children():
		if slot.get_children().empty():
			slot.add_child(action_button)
			
			return action_button
	
	print("Inventory is full")
	return null


func remove_item(index: int) -> void:
	var slot = $VBoxContainer/GridContainer.get_child(index)
	
	for child in slot.get_children():
		child.queue_free()
