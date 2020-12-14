extends TextureRect

var ability_entry_scene = load("res://Gameplay/UI/Spellbook/AbilityEntry.tscn")

var _held := false


func _on_GrabBox_button_down() -> void:
	_held = true


func _on_GrabBox_button_up() -> void:
	_held = false


func _on_CloseButton_pressed():
	hide()


func _input(event) -> void:
	if event is InputEventMouseMotion && _held:
		rect_position += event.relative


func add_entry(name: String, action_button: ActionButton) -> void:
	var entry = ability_entry_scene.instance()
	entry.setup(name, action_button)
	
	$MarginContainer/VBoxContainer/GridContainer.add_child(entry)
