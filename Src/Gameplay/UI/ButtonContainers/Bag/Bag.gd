extends ButtonContainer

const NAME = "Bag"

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


func _ready() -> void:
	var slots_container = $VBoxContainer/GridContainer;
	setup(NAME, slots_container)
