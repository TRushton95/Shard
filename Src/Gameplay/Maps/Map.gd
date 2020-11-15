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


func _on_unit_damage_received(value: int, unit: Unit) -> void:
	if unit == selected_unit:
		$CanvasLayer/TargetFrame.update()


func _on_unit_healing_received(value: int, unit: Unit) -> void:
	if unit == selected_unit:
		$CanvasLayer/TargetFrame.update()


func _on_unit_casting_started(ability_name: String, duration: float, unit: Unit) -> void:
	if unit == get_node(player_name):
		$CanvasLayer/CastBar.initialise(ability_name, duration)
		$CanvasLayer/CastBar.show()


func _on_unit_casting_stopped(unit: Unit) -> void:
	if unit == get_node(player_name):
		$CanvasLayer/CastBar.hide()


func _on_unit_casting_progress(value: float, unit: Unit) -> void:
	if unit == get_node(player_name):
		$CanvasLayer/CastBar.set_value(value)


func _process(delta: float) -> void:
	var ability_index = -1
	
	if Input.is_action_just_pressed("cast_1"):
		ability_index = 0
	
	if ability_index >= 0:
		if get_node(player_name).is_moving():
			print("Cannot cast while moving")
			return
		
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
			var movement_path = $Navigation2D.get_simple_path(get_node(player_name).position, event.position)
			
			$PathDebug.points = movement_path
			$PathDebug.show()
			get_node(player_name).rpc("set_movement_path", movement_path)
			
		elif event.button_index == BUTTON_LEFT:
			if selected_unit:
				selected_unit = null
				$CanvasLayer/TargetFrame.hide()


remotesync func cast_ability(ability_index, caster_name, target_name):
	var caster = get_node(caster_name)
	
	var target = target_name
	if has_node(target_name):
		target = get_node(target_name)
	
	caster.cast(ability_index, target)


func setup(player_name: String, player_lookup: Dictionary):
	self.player_name = player_name
	
	#TEST ENEMY
	$Enemy.connect("left_clicked", self, "_on_unit_left_clicked", [$Enemy])
	$Enemy.connect("damage_received", self, "_on_unit_damage_received", [$Enemy])
	$Enemy.connect("healing_received", self, "_on_unit_healing_received", [$Enemy])
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
		unit.connect("damage_received", self, "_on_unit_damage_received", [unit])
		unit.connect("healing_received", self, "_on_unit_healing_received", [unit])
		unit.connect("casting_started", self, "_on_unit_casting_started", [unit])
		unit.connect("casting_stopped", self, "_on_unit_casting_stopped", [unit])
		unit.connect("casting_progress", self, "_on_unit_casting_progress", [unit])
		
		if player == player_name:
			unit.connect("path_finished", self, "_on_player_path_finished")
		
		spawn_index += 1
