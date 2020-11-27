extends Node2D

var rainbow_cursor = load("res://pointer.png")
var unit_scene = load("res://Gameplay/Entities/Unit/Unit.tscn")
var floating_text_scene = load("res://Gameplay/UI/FloatingText/FloatingText.tscn")

var player_name : String
var selected_unit : Unit
var selected_ability


#This should hook into whatever mechanism determines when an ability key is pressed
func _on_ability_button_pressed(ability) -> void:
	process_ability_press(ability)


func _on_ability_button_mouse_entered(button: TextureButton, ability) -> void:
	$CanvasLayer/Tooltip.set_name(ability.name)
	$CanvasLayer/Tooltip.set_range(100)
	$CanvasLayer/Tooltip.set_cost(10)
	$CanvasLayer/Tooltip.set_cast_time(ability.cast_time)
	$CanvasLayer/Tooltip.set_description("Hello there")
	
	var channel_cost = -1
	var tick_rate = -1
	if "channel_cost" in ability && "tick_rate" in ability:
		channel_cost = ability.channel_cost
		tick_rate = ability.tick_rate
		
	$CanvasLayer/Tooltip.set_channel(channel_cost, tick_rate)
	$CanvasLayer/Tooltip.rect_size.y = 0 # Needed to force panel to resize after removing items from the HBoxContainer, hide/show should do this, don't know why it's not
	$CanvasLayer/Tooltip.show() # Must be shown before calculating position to force size recalculation
	$CanvasLayer/Tooltip.rect_position = button.get_global_rect().position - Vector2(0, $CanvasLayer/Tooltip.rect_size.y + 20)


func _on_ability_button_mouse_exited(ability) -> void:
	$CanvasLayer/Tooltip.hide()


func _on_unit_left_clicked(unit: Unit) -> void:
	if selected_ability:
		rpc("cast_ability_on_unit", selected_ability.get_index(), player_name, unit.name)
		select_unit(unit)
		select_ability(null)
	else:
		select_unit(unit)


func _on_unit_right_clicked(unit: Unit) -> void:
	var player = get_node(player_name)
	
	if unit != player:
		var movement_path = $Navigation2D.get_simple_path(player.position, unit.position)
		$PathDebug.points = movement_path
		$PathDebug.show()
		rpc("_set_unit_focus", player_name, unit.name)
		player.rpc("set_movement_path", movement_path)
		player.get_node("FollowPathingTimer").start(1.0)


func _on_player_path_finished() -> void:
	$PathDebug.hide()


func _on_unit_follow_path_outdated(unit: Unit) -> void:
	var player = get_node(player_name) # Should maybe be using is_networking_master() for this?
	
	if unit == player:
		var M := 0.0004 # M in a linear equation to calculate the follow path invalidation time based on distance, may need fine tuning as gameplay emerges
		var PATH_INVALIDATE_TIME_MINIMUM := 0.2 # C in the linear equation
		var distance = player.position.distance_to(player.focus.position)
		var invalidate_time = (M * distance) + PATH_INVALIDATE_TIME_MINIMUM # Time until path is next invalidated
		
		var movement_path = $Navigation2D.get_simple_path(player.position, player.focus.position)
		$PathDebug.points = movement_path
		$PathDebug.show()
		player.rpc("set_movement_path", movement_path)
		player.get_node("FollowPathingTimer").start(invalidate_time)


#DEBUG FOLLOW PATHING PURPOSES ONLY
func _on_enemy_follow_path_outdated(unit: Unit) -> void:
	if unit == $Enemy:
		var movement_path = $Navigation2D.get_simple_path($Enemy.position, $Enemy.focus.position)
		$Enemy.rpc("set_movement_path", movement_path)
		
		var UPDATE_CONST = 0.0004
		var update_rate = (UPDATE_CONST * $Enemy.position.distance_to($Enemy.focus.position)) + 0.2
		$Enemy.get_node("FollowPathingTimer").start(update_rate)
#DEBUG FOLLOW PATHING PURPOSES ONLY


func _on_unit_status_effect_applied(status_effect: Status, unit: Unit) -> void:
	if unit == get_node(player_name):
		$CanvasLayer/StatusEffectBar.add_status_effect(status_effect)
	
	if unit == selected_unit:
		$CanvasLayer/TargetFrame.add_status_effect(status_effect)


func _on_unit_status_effect_removed(_status_effect: Status, index: int, unit: Unit) -> void:
	if unit == get_node(player_name):
		$CanvasLayer/StatusEffectBar.remove_status_effect(index)
	
	if unit == selected_unit:
		$CanvasLayer/TargetFrame.remove_status_effect(index)


func _on_player_health_attr_changed(value: int) -> void:
	$CanvasLayer/CharacterPanel.set_health_attr(value)
	$CanvasLayer/ActionBar.set_max_health(value)
	
	if selected_unit == get_node(player_name):
		$CanvasLayer/TargetFrame.set_max_health(value)


func _on_player_mana_attr_changed(value: int) -> void:
	$CanvasLayer/CharacterPanel.set_mana_attr(value)
	$CanvasLayer/ActionBar.set_max_mana(value)
	
	if selected_unit == get_node(player_name):
		$CanvasLayer/TargetFrame.set_max_mana(value)


func _on_player_attack_power_attr_changed(value: int) -> void:
	$CanvasLayer/CharacterPanel.set_attack_power_attr(value)


func _on_player_spell_power_attr_changed(value: int) -> void:
	$CanvasLayer/CharacterPanel.set_spell_power_attr(value)


func _on_player_movement_speed_attr_changed(value: int) -> void:
	$CanvasLayer/CharacterPanel.set_movement_speed_attr(value)


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


func _on_auto_attack_cooldown_started(duration: float) -> void:
	$CanvasLayer/AutoAttackBar.initialise("Basic attack cooldown", duration)
	$CanvasLayer/AutoAttackBar.show()


func _on_auto_attack_cooldown_progressed(time_remaining: float) -> void:
	$CanvasLayer/AutoAttackBar.set_value(time_remaining)


func _on_auto_attack_cooldown_ended() -> void:
	$CanvasLayer/AutoAttackBar.hide()


var mana_modifier = Modifier.new(Enums.ModifierType.Additive, 5)

func _process(_delta: float) -> void:
	var player = get_node(player_name)
	
	var ability_index = -1
	
	# Test commands for testing whatever
	if Input.is_action_just_pressed("test_right"):
		player.mana_attr.push_modifier(mana_modifier)
	if Input.is_action_just_pressed("test_left"):
		player.mana_attr.remove_modifier(mana_modifier)
	# End of test commands
	
	if Input.is_action_just_pressed("toggle_character_panel"):
		$CanvasLayer/CharacterPanel.visible = !$CanvasLayer/CharacterPanel.visible
	
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
		player.rset("current_mana", player.mana_attr.value)
	
	if ability_index >= 0:
		var ability = player.get_node("Abilities").get_child(ability_index)
		
		if !"target_type" in ability:
			print("No target type on ability " + ability.name)
			return
			
		# This method can be moved back here but needs to map key inputs properly and expose in a way
		# that action bar button press can hook into as well
		process_ability_press(ability)
		
	for status in player.get_node("StatusEffects").get_children():
		var index = status.get_index()
		$CanvasLayer/StatusEffectBar.update_duration(index, status.get_time_remaining())
		
	if selected_unit:
		for status in selected_unit.get_node("StatusEffects").get_children():
			var status_index = status.get_index()
			$CanvasLayer/TargetFrame.update_status_effect_duration(status_index, status.get_time_remaining())


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
				
			var player = get_node(player_name)
			var movement_path = $Navigation2D.get_simple_path(player.position, event.position)
			$PathDebug.points = movement_path
			$PathDebug.show()
			player.get_node("FollowPathingTimer").stop()
			player.rpc("set_movement_path", movement_path)
			rpc("_set_unit_focus", player_name, "")
			
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
	$Enemy.connect("right_clicked", self, "_on_unit_right_clicked", [$Enemy])
	$Enemy.connect("follow_path_outdated", self, "_on_enemy_follow_path_outdated", [$Enemy])
	$Enemy.connect("damage_received", self, "_on_unit_damage_received", [$Enemy])
	$Enemy.connect("healing_received", self, "_on_unit_healing_received", [$Enemy])
	$Enemy.connect("status_effect_applied", self, "_on_unit_status_effect_applied", [$Enemy])
	$Enemy.connect("status_effect_removed", self, "_on_unit_status_effect_removed", [$Enemy])
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
		unit.connect("right_clicked", self, "_on_unit_right_clicked", [unit])
		unit.connect("follow_path_outdated", self, "_on_unit_follow_path_outdated", [unit])
		unit.connect("damage_received", self, "_on_unit_damage_received", [unit])
		unit.connect("healing_received", self, "_on_unit_healing_received", [unit])
		unit.connect("mana_changed", self, "_on_unit_mana_changed", [unit])
		unit.connect("casting_started", self, "_on_unit_casting_started", [unit])
		unit.connect("casting_progressed", self, "_on_unit_casting_progressed", [unit])
		unit.connect("casting_stopped", self, "_on_unit_casting_stopped", [unit])
		unit.connect("channelling_started", self, "_on_unit_channelling_started", [unit])
		unit.connect("channelling_progressed", self, "_on_unit_channelling_progressed", [unit])
		unit.connect("channelling_stopped", self, "_on_unit_channelling_stopped", [unit])
		unit.connect("status_effect_applied", self, "_on_unit_status_effect_applied", [unit])
		unit.connect("status_effect_removed", self, "_on_unit_status_effect_removed", [unit])
		
		if player == player_name:
			unit.connect("path_finished", self, "_on_player_path_finished")
			unit.connect("health_attr_changed", self, "_on_player_health_attr_changed")
			unit.connect("mana_attr_changed", self, "_on_player_mana_attr_changed")
			unit.connect("attack_power_attr_changed", self, "_on_player_attack_power_attr_changed")
			unit.connect("spell_power_attr_changed", self, "_on_player_spell_power_attr_changed")
			unit.connect("movement_speed_attr_changed", self, "_on_player_movement_speed_attr_changed")
			unit.connect("auto_attack_cooldown_started", self, "_on_auto_attack_cooldown_started")
			unit.connect("auto_attack_cooldown_ended", self, "_on_auto_attack_cooldown_ended")
			unit.connect("auto_attack_cooldown_progressed", self, "_on_auto_attack_cooldown_progressed")
			
			for ability in unit.get_node("Abilities").get_children():
				var ability_button = $CanvasLayer/ActionBar.add_ability(ability)
				ability_button.connect("pressed", self, "_on_ability_button_pressed", [ability])
				ability_button.connect("mouse_entered", self, "_on_ability_button_mouse_entered", [ability_button, ability])
				ability_button.connect("mouse_exited", self, "_on_ability_button_mouse_exited", [ability])
			
			$CanvasLayer/ActionBar.set_max_health(unit.health_attr.value)
			$CanvasLayer/ActionBar.set_max_mana(unit.mana_attr.value)
			$CanvasLayer/CharacterPanel.set_character_name(player_name)
			$CanvasLayer/CharacterPanel.set_character_image(unit.get_node("Sprite").texture)
			$CanvasLayer/CharacterPanel.set_health_attr(unit.health_attr.value)
			$CanvasLayer/CharacterPanel.set_mana_attr(unit.mana_attr.value)
			$CanvasLayer/CharacterPanel.set_attack_power_attr(unit.attack_power_attr.value)
			$CanvasLayer/CharacterPanel.set_spell_power_attr(unit.spell_power_attr.value)
			$CanvasLayer/CharacterPanel.set_movement_speed_attr(unit.movement_speed_attr.value)
			
			# PATHING TEST #
#			$Enemy.rset("focus", unit)
#			var movement_path = $Navigation2D.get_simple_path($Enemy.position, unit.position)
#			$Enemy.rpc("set_movement_path", movement_path)
#			$Enemy.get_node("FollowPathingTimer").start(1.0)
			# PATHING TEST #
			
		spawn_index += 1


func select_unit(unit: Unit) -> void:
	if unit:
		selected_unit = unit
		print(str(unit.health_attr.value))
		$CanvasLayer/TargetFrame.set_max_health(unit.health_attr.value)
		$CanvasLayer/TargetFrame.set_max_mana(unit.mana_attr.value)
		$CanvasLayer/TargetFrame.set_current_health(unit.current_health)
		$CanvasLayer/TargetFrame.set_current_mana(unit.current_mana)
		$CanvasLayer/TargetFrame.set_name(unit.name)
		$CanvasLayer/TargetFrame.set_image(unit.get_node("Sprite").texture)
		$CanvasLayer/TargetFrame.clear_status_effects()
		for status_effect in unit.get_node("StatusEffects").get_children():
			$CanvasLayer/TargetFrame.add_status_effect(status_effect)
			
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


remotesync func _set_unit_focus(unit_name: String, focus_name: String) -> void:
	var unit = get_node(unit_name)
	var focus = get_node(focus_name) if focus_name else null
	
	unit.focus = focus
