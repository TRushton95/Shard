extends Node


func _unhandled_input(event):
	if event is InputEventMouseButton && event.button_index == BUTTON_RIGHT && event.pressed:
		var path = $Navigation2D.get_simple_path($Unit.position, event.position)
		
		$PathDebug.points = path
		$PathDebug.show()
		$Unit.path = path


func _on_Unit_path_finished():
	$PathDebug.hide()
