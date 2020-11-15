extends Node

var unit_scene = load("Gameplay/Entities/Unit/Unit.tscn")

var player_name : String


func _on_player_unit_path_finished() -> void:
	$PathDebug.hide()


func _unhandled_input(event):
	if event is InputEventMouseButton && event.button_index == BUTTON_RIGHT && event.pressed:
		var path = $Navigation2D.get_simple_path(get_node(player_name).position, event.position)
		
		$PathDebug.points = path
		$PathDebug.show()
		get_node(player_name).rpc("set_path", path)



func setup(player_name: String, player_list: Dictionary):
	self.player_name = player_name
	var player_unit = unit_scene.instance()
	player_unit.name = player_name
	add_child(player_unit)
	player_unit.connect("path_finished", self, "_on_player_unit_path_finished")
	
	for player in player_list:
		var unit = unit_scene.instance()
		unit.name = player_list[player]
		add_child(unit)
