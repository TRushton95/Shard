extends Node

var rainbow_cursor = load("res://pointer.png")
var unit_scene = load("Gameplay/Entities/Unit/Unit.tscn")
var floating_text_scene = load("Gameplay/UI/FloatingText/FloatingText.tscn")

var player_name : String
var selected_unit : Unit
var selected_ability


#This should hook into whatever mechanism determines when an ability key is pressed
func _on_AbilityBar_ability_button_pressed(ability) -> void:
	process_ability_press(ability)


func _on_unit_left_clicked(unit: Unit) -> void:
	if selected_ability:
		rpc("cast_ability_on_unit", selected_ability.get_index(), player_name, unit.name)
		select_unit(unit)
		select_ability(null)
	else:
		select_unit(unit)


func _on_player_path_finished() -> void:
	$PathDebug.hide()


func _on_unit_damage_received(value: int, unit: Unit) -> void:
	var floating_text = floating_text_scene.instance()
	floating_text.setup(value, unit.position, Color.red)
	add_child(floating_text)
	
	if unit == selected_unit:
		$CanvasLayer/TargetFrame.set_current_health(unit.current_health)
		
	if unit == get_node(player_name):
		$CanvasLayer/ActionBar.set_current_health(unit.current_health)


func _on_unit_healing_received(value: int, unit: Unit) -> void:
	var floating_text = floating_text_scene.instance()
	floating_text.setup(value, unit.position, Color.green)
	add_child(floating_text)
	
	if unit == selected_unit:
		$CanvasLayer/TargetFrame.set_current_health(unit.current_health)
		
	if unit == get_node(player_name):
		$CanvasLayer/ActionBar.set_current_health(unit.current_health)


func _on_unit_mana_changed(value: int, unit: Unit) -> void:
	if unit == selected_unit:
		$CanvasLayer/TargetFrame.set_current_mana(unit.current_mana)
	
	if unit == get_node(player_name):
		$CanvasLayer/ActionBar.set_current_mana(unit.current_mana)


func _on_unit_casting_started(ability_name: String, duration: float, unit: Unit) -> void:
	if unit == get_node(player_name):
		$CanvasLayer/CastBar.initialise(ability_name, duration)
		$CanvasLayer/CastBar.show()


func _on_unit_casting_progressed(time_elapsed: float, unit: Unit) -> void:
	if unit == get_node(player_name):
		$CanvasLayer/CastBar.set_value(time_elapsed)


func _on_unit_casting_stopped(unit: Unit) -> void:
	if unit == get_node(player_name):
		$CanvasLayer/CastBar.hide()


func _on_unit_channelling_started(ability_name: String, channel_duration: float, unit: Unit) -> void:
	if unit == get_node(player_name):
		$CanvasLayer/CastBar.initialise(ability_name, channel_duration)
		$CanvasLayer/CastBar.show()


func _on_unit_channelling_progressed(time_remaining: float, unit: Unit) -> void:
	if unit == get_node(player_name):
		$CanvasLayer/CastBar.set_value(time_remaining)


func _on_unit_channelling_stopped(unit: Unit) -> void:
	if unit == get_node(player_name):
		$CanvasLayer/CastBar.hide()

func _process(delta: float) -> void:
	var player = get_node(player_name)
	
	var ability_index = -1
	
	# Test commands for testing whatever
	if Input.is_action_just_pressed("test_right"):
		pass
	if Input.is_action_just_pressed("test_left"):
		pass
	# End of test commands
	
	if Input.is_action_just_pressed("cast_1"):
		ability_index = 0
	if Input.is_action_just_pressed("cast_2"):
		ability_index = 1
	if Input.is_action_just_pressed("cast_3"):
		ability_index = 2
	if Input.is_action_just_pressed("stop"):
		if player.casting_index >= 0 || player.channelling_index >= 0:
			player.rpc("interrupt")
		if player.is_moving():
			player.rpc("set_movement_path", [])
	
	if Input.is_action_just_pressed("test_interrupt"):
		player.rpc("interrupt")
	if Input.is_action_just_pressed("test_mana_refill"):
		player.rset("current_mana", player.max_mana)
	
	if ability_index >= 0:
		var ability = player.get_node("Abilities").get_child(ability_index)
		
		if !"target_type" in ability:
			print("No target type on ability " + ability.name)
			return
			
		# This method can be moved back here but needs to map key inputs properly and expose in a way
		# that action bar button press can hook into as well
		process_ability_press(ability)


func process_ability_press(ability):
	match ability.target_type:
		Enums.TargetType.Unit:
			if selected_unit:
				rpc("cast_ability_on_unit", ability.get_index(), player_name, selected_unit.name)
			else:
				select_ability(ability)
				
		Enums.TargetType.Position:
			select_ability(ability)


func _unhandled_input(event) -> void:
	if event is InputEventMouseButton && event.pressed:
		if event.button_index == BUTTON_RIGHT:
			if selected_ability:
				select_ability(null)
				
			var movement_path = $Navigation2D.get_simple_path(get_node(player_name).position, event.position)
			$PathDebug.points = movement_path
			$PathDebug.show()
			get_node(player_name).rpc("set_movement_path", movement_path)
			
		elif event.button_index == BUTTON_LEFT:
			if selected_ability && selected_ability.target_type == Enums.TargetType.Position:
				rpc("cast_ability_at_position", selected_ability.get_index(), player_name, event.position)
				select_ability(null)
			else:
				select_unit(null)


remotesync func cast_ability_on_unit(ability_index: int, caster_name: String, target_name: String) -> void:
	var caster = get_node(caster_name)
	
	if !has_node(target_name):
		print("No target with name: " + target_name)
		
	var target = get_node(target_name)
	caster.cast(ability_index, target)


remotesync func cast_ability_at_position(ability_index: int, caster_name, target_position: Vector2) -> void:
	var caster = get_node(caster_name)
	caster.cast(ability_index, target_position)


func setup(player_name: String, player_lookup: Dictionary) -> void:
	self.player_name = player_name
	
	#TEST ENEMY
	$Enemy.set_name($Enemy.name) # set name label
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
		unit.set_name(player)
		unit.position = $PlayerSpawnPoints.get_node(str(spawn_index)).position
		add_child(unit)
		unit.connect("left_clicked", self, "_on_unit_left_clicked", [unit])
		unit.connect("damage_received", self, "_on_unit_damage_received", [unit])
		unit.connect("healing_received", self, "_on_unit_healing_received", [unit])
		unit.connect("mana_changed", self, "_on_unit_mana_changed", [unit])
		unit.connect("casting_started", self, "_on_unit_casting_started", [unit])
		unit.connect("casting_progressed", self, "_on_unit_casting_progressed", [unit])
		unit.connect("casting_stopped", self, "_on_unit_casting_stopped", [unit])
		unit.connect("channelling_started", self, "_on_unit_channelling_started", [unit])
		unit.connect("channelling_progressed", self, "_on_unit_channelling_progressed", [unit])
		unit.connect("channelling_stopped", self, "_on_unit_channelling_stopped", [unit])
		
		if player == player_name:
			unit.connect("path_finished", self, "_on_player_path_finished")
			$CanvasLayer/ActionBar.setup_abilities(unit.get_node("Abilities").get_children())
			$CanvasLayer/ActionBar.set_max_health(unit.max_health)
			$CanvasLayer/ActionBar.set_max_mana(unit.max_mana)
		
		spawn_index += 1


func select_unit(unit: Unit) -> void:
	if unit:
		selected_unit = unit
		$CanvasLayer/TargetFrame.set_max_health(unit.max_health)
		$CanvasLayer/TargetFrame.set_max_mana(unit.max_mana)
		$CanvasLayer/TargetFrame.set_current_health(unit.current_health)
		$CanvasLayer/TargetFrame.set_current_mana(unit.current_mana)
		$CanvasLayer/TargetFrame.set_name(unit.name)
		$CanvasLayer/TargetFrame.set_image(unit.get_node("Sprite").texture)
		$CanvasLayer/TargetFrame.show()
	else:
		selected_unit = null
		$CanvasLayer/TargetFrame.hide()


func select_ability(ability) -> void:
	if !ability:
		selected_ability = null
		Input.set_custom_mouse_cursor(null)
	else:
		selected_ability = ability
		Input.set_custom_mouse_cursor(rainbow_cursor)
