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


func add_action_button(action_button: ActionButton) -> void:
	for slot in $VBoxContainer/GridContainer.get_children():
		if slot.is_free():
			slot.add_button(action_button)
			return
	
	print("Inventory is full")


func remove_action_button(index: int) -> void:
	var slot = $VBoxContainer/GridContainer.get_child(index)
	
	if !slot.is_empty():
		var button = slot.pop_button()
		button.queue_free()
