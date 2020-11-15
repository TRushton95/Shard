extends Node


func _on_client_connected(id: int) -> void:
	pass
	


func _unhandled_input(event):
	if event is InputEventMouseButton && event.button_index == BUTTON_RIGHT && event.pressed:
		var path = $Navigation2D.get_simple_path($Unit.position, event.position)
		
		$PathDebug.points = path
		$PathDebug.show()
		get_node(get_tree().get_network_unique_id()).rpc("set_path", path)


func _on_Unit_path_finished():
	$PathDebug.hide()


func _ready():
	get_tree().connect("network_peer_connected", self, "_on_client_connected")
#	get_tree().connect("network_peer_disconnected", self, "_on_client_disconnected")
