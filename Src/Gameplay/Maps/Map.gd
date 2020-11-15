extends Node

var unit_scene = load("Gameplay/Entities/Unit/Unit.tscn")

var player_name : String
var selected_unit : Unit


func _on_unit_left_clicked(unit: Unit) -> void:
	selected_unit = unit
	$CanvasLayer/TargetFrame.set_profile(unit)
	$CanvasLayer/TargetFrame.show()


func _on_player_path_finished() -> void:
	$PathDebug.hide()


func _on_unit_damage_received(unit, value) -> void:
	if unit == selected_unit:
		$CanvasLayer/TargetFrame.update()


func _on_unit_healing_received(unit, value) -> void:
	if unit == selected_unit:
		$CanvasLayer/TargetFrame.update()


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
					rpc("cast_ability", ability_index, player_name, selected_unit.name)
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
				selected_unit = null
				$CanvasLayer/TargetFrame.hide()


remotesync func cast_ability(ability_index, caster_name, target_name):
	var caster = get_node(caster_name)
	var target = get_node(target_name)
	var ability = caster.get_node("Abilities").get_child(ability_index)
	
	ability.execute(target, caster)


func setup(player_name: String, player_lookup: Dictionary):
	self.player_name = player_name
	
	#TEST ENEMY
	$Enemy.connect("left_clicked", self, "_on_unit_left_clicked", [$Enemy])
	$Enemy.connect("damage_received", self, "_on_unit_damage_received")
	$Enemy.connect("healing_received", self, "_on_unit_healing_received")
	#END OF TEST ENEMY
	
	var player_list = player_lookup.values()
	player_list.append(player_name)
	player_list.sort()
	
	var spawn_index = 0
	for player in player_list:
		var unit = unit_scene.instance()
		unit.name = player
		unit.position = $PlayerSpawnPoints.get_node(str(spawn_index)).position
		add_child(unit)
		unit.connect("left_clicked", self, "_on_unit_left_clicked", [unit])
		unit.connect("damage_received", self, "_on_unit_damage_received")
		unit.connect("healing_received", self, "_on_unit_healing_received")
		
		if player == player_name:
			unit.connect("path_finished", self, "_on_player_path_finished")
		
		spawn_index += 1
