extends Node

var unit_scene = load("Gameplay/Entities/Unit/Unit.tscn")

var player_name : String
var selected_unit : Unit


func _on_unit_left_clicked(unit: Unit) -> void:
	print("selected unit")
	selected_unit = unit


func _on_player_path_finished() -> void:
	$PathDebug.hide()


func _process(delta: float) -> void:
	var ability_index = -1
	
	if Input.is_action_just_pressed("cast_1"):
		ability_index = 0
	
	if ability_index >= 0:
		var ability = get_node(player_name + "/Abilities").get_child(ability_index)
		
		if !"target_type" in ability:
			print("No target type on ability " + ability.name)
			return
			
		match ability.target_type:
			Enums.TargetType.Unit:
				if selected_unit:
					ability.execute(selected_unit, get_node(player_name))
				else:
					print("No selected unit")

func _unhandled_input(event):
	if event is InputEventMouseButton && event.pressed:
		if event.button_index == BUTTON_RIGHT:
			var path = $Navigation2D.get_simple_path(get_node(player_name).position, event.position)
			
			$PathDebug.points = path
			$PathDebug.show()
			get_node(player_name).rpc("set_path", path)
			
		elif event.button_index == BUTTON_LEFT:
			if selected_unit:
				print("deselected unit")
				selected_unit = null


func setup(player_name: String, player_list: Dictionary):
	self.player_name = player_name
	var player_unit = unit_scene.instance()
	player_unit.name = player_name
	add_child(player_unit)
	player_unit.connect("path_finished", self, "_on_player_path_finished")
	player_unit.connect("left_clicked", self, "_on_unit_left_clicked", [player_unit])
	
	for player in player_list:
		var unit = unit_scene.instance()
		unit.name = player_list[player]
		add_child(unit)
		unit.connect("left_clicked", self, "_on_unit_left_clicked", [unit])
