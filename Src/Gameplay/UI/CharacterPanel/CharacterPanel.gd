extends TextureRect

var held := false


func _on_GrabBox_button_down() -> void:
	held = true


func _on_GrabBox_button_up() -> void:
	held = false


func _input(event) -> void:
	if event is InputEventMouseMotion && held:
		rect_position += event.relative
