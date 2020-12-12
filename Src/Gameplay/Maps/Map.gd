extends Node2D

var rainbow_cursor = load("res://pointer.png")
var unit_scene = load("res://Gameplay/Entities/Unit/Unit.tscn")
var floating_text_scene = load("res://Gameplay/UI/FloatingText/FloatingText.tscn")
var action_button_scene = load("res://Gameplay/UI/ActionButton/ActionButton.tscn")

var player_name : String
var selected_unit : Unit
var selected_ability
var grab_offset : Vector2


#This should hook into whatever mechanism determines when an ability key is clicked
func _on_ability_button_pressed(button: ActionButton) -> void:
	var ability = find_action(button.action_lookup)
	process_ability_press(ability)


func _on_ability_button_mouse_entered(button: ActionButton) -> void:
	if button.action_lookup.source == Enums.ActionSource.Ability:
		var ability = get_node(player_name + "/Abilities").get_child(button.action_lookup.index)
		
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


func _on_ability_button_mouse_exited(button: ActionButton) -> void:
	$CanvasLayer/Tooltip.hide()


func _on_ability_button_dragged() -> void:
	$CanvasLayer/Tooltip.hide()


func _on_Bag_button_dropped_in_slot(action_button: ActionButton, button_slot: ButtonSlot) -> void:
	match action_button.source:
		Enums.ButtonSource.Bag:
			var from_index = $CanvasLayer/Bag.get_button_index(action_button)
			var to_index = button_slot.get_index()
			$CanvasLayer/Bag.move(from_index, to_index)
			get_node(player_name + "/Inventory").move(from_index, to_index)


func _on_Bag_button_dropped_on_button(dropped_button: ActionButton, target_button: ActionButton) -> void:
	match dropped_button.source:
		Enums.ButtonSource.Bag:
			var from_index = $CanvasLayer/Bag.get_button_index(dropped_button)
			var to_index = $CanvasLayer/Bag.get_button_index(target_button)
			$CanvasLayer/Bag.move(from_index, to_index)
			get_node(player_name + "/Inventory").move(from_index, to_index)


func _on_ActionBar_button_dropped_in_slot(button: ActionButton, button_slot: ButtonSlot) -> void:
	match button.source:
		Enums.ButtonSource.Bag:
			var clone_button = _create_action_button(button.action_name, button.texture_normal, button.action_lookup.source, button.action_lookup.index, Enums.ButtonSource.ActionBar)
			button_slot.add_button(clone_button)
			
		Enums.ButtonSource.ActionBar:
			var from_index = $CanvasLayer/ActionBar.get_button_index(button)
			var to_index = button_slot.get_index()
			$CanvasLayer/ActionBar.move(from_index, to_index)


func _on_ActionBar_button_dropped_on_button(dropped_button: ActionButton, target_button: ActionButton) -> void:
	var clone_button = target_button.duplicate()
	target_button.force_drag(target_button, clone_button)


func _on_unit_left_clicked(unit: Unit) -> void:
	if selected_ability:
		var player = get_node(player_name)
		
		if !_is_team_target_valid(selected_ability, unit):
			print("Invalid target")
		
		rpc("_set_unit_queued_ability_data", player_name, unit.name, selected_ability.get_index())
		_pursue_target(unit.name)
		select_unit(unit)
		select_ability(null)
	else:
		select_unit(unit)


func _on_unit_right_clicked(unit: Unit) -> void:
	var player = get_node(player_name)
	
	if unit != player && unit.team != player.team:
		_pursue_target(unit.name)


func _on_player_path_finished() -> void:
	$PathDebug.hide()


func _on_unit_follow_path_outdated(unit: Unit) -> void:
	var player = get_node(player_name) # TODO: Should maybe be using is_networking_master() for this?
	
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
			
		for ability in unit.get_node("Abilities").get_children():
			for action_button in _get_action_buttons_by_action_name(ability.name):
				action_button.set_unaffordable_filter_visibility(unit.current_mana < ability.cost)


func _on_unit_casting_started(ability_name: String, duration: float, unit: Unit) -> void:
	if unit == get_node(player_name):
		$CanvasLayer/CastBar.initialise(ability_name, duration)
		$CanvasLayer/CastBar.show()
		
		for action_button in _get_action_buttons_by_action_name(ability_name):
			action_button.set_active(true)


func _on_unit_casting_progressed(time_elapsed: float, unit: Unit) -> void:
	if unit == get_node(player_name):
		$CanvasLayer/CastBar.set_value(time_elapsed)


func _on_unit_casting_stopped(ability_name: String, unit: Unit) -> void:
	if unit == get_node(player_name):
		$CanvasLayer/CastBar.hide()
		
	for action_button in _get_action_buttons_by_action_name(ability_name):
		action_button.set_active(false)


func _on_unit_channelling_started(ability_name: String, channel_duration: float, unit: Unit) -> void:
	if unit == get_node(player_name):
		$CanvasLayer/CastBar.initialise(ability_name, channel_duration)
		$CanvasLayer/CastBar.show()
		
		for action_button in _get_action_buttons_by_action_name(ability_name):
			action_button.set_active(true)


func _on_unit_channelling_progressed(time_remaining: float, unit: Unit) -> void:
	if unit == get_node(player_name):
		$CanvasLayer/CastBar.set_value(time_remaining)


func _on_unit_channelling_stopped(ability_name: String, unit: Unit) -> void:
	if unit == get_node(player_name):
		$CanvasLayer/CastBar.hide()
		
		for action_button in _get_action_buttons_by_action_name(ability_name):
			action_button.set_active(false)


func _on_auto_attack_cooldown_started(duration: float) -> void:
	$CanvasLayer/AutoAttackBar.initialise("Basic attack cooldown", duration)
	$CanvasLayer/AutoAttackBar.show()


func _on_auto_attack_cooldown_progressed(time_remaining: float) -> void:
	$CanvasLayer/AutoAttackBar.set_value(time_remaining)


func _on_auto_attack_cooldown_ended() -> void:
	$CanvasLayer/AutoAttackBar.hide()


func _on_ability_cooldown_started(ability: Ability, duration: int) -> void:
	for action_button in _get_action_buttons_by_action_name(ability.name):
		action_button.set_max_cooldown(duration)
		action_button.set_cooldown(duration)
		action_button.show_cooldown()


func _on_ability_cooldown_progressed(ability: Ability) -> void:
	for action_button in _get_action_buttons_by_action_name(ability.name):
		action_button.set_cooldown(ability.get_remaining_cooldown())


func _on_ability_cooldown_ended(ability: Ability) -> void:
	for action_button in _get_action_buttons_by_action_name(ability.name):
		action_button.hide_cooldown()


func _on_unit_team_changed(unit: Unit) -> void:
	if unit.team == get_node(player_name).team:
		unit.set_health_bar_color(Color.green)
	else:
		unit.set_health_bar_color(Color.red)


var mana_modifier = Modifier.new(5, Enums.ModifierType.Additive)

func _process(_delta: float) -> void:
	var player = get_node(player_name)
	
	# Test commands for testing whatever
	if Input.is_action_just_pressed("test_right"):
		player.get_node("Inventory").pop_item(0)
		$CanvasLayer/Bag.remove_action_button(0)
	if Input.is_action_just_pressed("test_left"):
		var fireball_scroll_scene = load("res://Gameplay/Entities/Items/FireballScroll.tscn")
		var fireball_scroll = fireball_scroll_scene.instance()
		var success = player.get_node("Inventory").push_item(fireball_scroll)
		
		if success:
			var item_ability = player.get_node("Inventory").get_item(0).get_ability()
			var icon = item_ability.icon # This should probably be the icon from the item, not the ability
			
			var item_button = _create_action_button(item_ability.name, icon, Enums.ActionSource.Inventory, item_ability.get_index(), Enums.ButtonSource.Bag)
			
			if player.get_node("Inventory").get_item(1):
				item_button.modulate = Color(0, 1, 1)
			
			$CanvasLayer/Bag.add_action_button(item_button)
	# End of test commands
	
	if Input.is_action_just_pressed("cancel"):
		if $CanvasLayer/CharacterPanel.visible:
			$CanvasLayer/CharacterPanel.visible = !$CanvasLayer/CharacterPanel.visible
		elif selected_unit:
			select_unit(null)
		elif selected_ability:
			select_ability(null)
	
	if Input.is_action_just_pressed("toggle_character_panel"):
		$CanvasLayer/CharacterPanel.visible = !$CanvasLayer/CharacterPanel.visible
	if Input.is_action_just_pressed("toggle_spellbook"):
		$CanvasLayer/Spellbook.visible = !$CanvasLayer/Spellbook.visible
	if Input.is_action_just_pressed("toggle_bag"):
		$CanvasLayer/Bag.visible = !$CanvasLayer/Bag.visible
	
	var button_index = -1
	if Input.is_action_just_pressed("cast_1"):
		button_index = 0
	if Input.is_action_just_pressed("cast_2"):
		button_index = 1
	if Input.is_action_just_pressed("cast_3"):
		button_index = 2
	if Input.is_action_just_pressed("cast_4"):
		button_index = 3
	if Input.is_action_just_pressed("cast_5"):
		button_index = 4
	if Input.is_action_just_pressed("cast_6"):
		button_index = 5
	if Input.is_action_just_pressed("cast_7"):
		button_index = 6
	if Input.is_action_just_pressed("cast_8"):
		button_index = 7
	if Input.is_action_just_pressed("cast_9"):
		button_index = 8
	if Input.is_action_just_pressed("cast_10"):
		button_index = 9
	if Input.is_action_just_pressed("cast_11"):
		button_index = 10
	if Input.is_action_just_pressed("cast_12"):
		button_index = 11
	if Input.is_action_just_pressed("stop"):
		if player.casting_index >= 0 || player.channelling_index >= 0:
			player.rpc("interrupt")
		if player.is_moving():
			player.rpc("set_movement_path", [])
		if player.focus:
			player.rpc("stop_pursuing")
	
	if Input.is_action_just_pressed("test_interrupt"):
		player.rpc("interrupt")
	if Input.is_action_just_pressed("test_mana_refill"):
		player.rset("current_mana", player.mana_attr.value)
	
	if button_index >= 0:
		var pressed_button = $CanvasLayer/ActionBar.get_button(button_index)
		
		if pressed_button:
			var ability = find_action(pressed_button.action_lookup)
		
			if ability.target_type == Enums.TargetType.Unset:
				print("Target type not set on casted ability " + ability.name)
				return
				
			# This method can be moved back here but needs to map key inputs properly and expose in a way
			# that action bar button press can hook into as well
			process_ability_press(ability)
		
	for status in player.get_node("StatusEffects").get_children():
		var index = status.get_index()
		if status.get_time_remaining() > 0:
			$CanvasLayer/StatusEffectBar.update_duration(index, status.get_time_remaining())
			
	if selected_unit:
		for status in selected_unit.get_node("StatusEffects").get_children():
			var status_index = status.get_index()
			if status.get_time_remaining() > 0:
				$CanvasLayer/TargetFrame.update_status_effect_duration(status_index, status.get_time_remaining())


func find_action(action_lookup: ActionLookup) -> Ability:
	var result
	
	if action_lookup.source == Enums.ActionSource.Ability:
		var ability = get_node(player_name + "/Abilities").get_child(action_lookup.index)
		result = ability
	elif action_lookup.source == Enums.ActionSource.Inventory:
		var item = get_node(player_name + "/Inventory").get_item(action_lookup.index)
		result = item.get_ability()
		
	return result


func process_ability_press(ability: Ability):
	if ability.is_on_cooldown():
		print("Ability while it is on cooldown")
		return
	
	match ability.target_type:
		Enums.TargetType.Self:
				rpc("cast_ability_on_unit", ability.get_index(), player_name, player_name)
		Enums.TargetType.Unit:
			if selected_unit:
				if !_is_team_target_valid(ability, selected_unit):
					print("Invalid target")
					return
				
				_pursue_target(selected_unit.name)
				rpc("_set_unit_queued_ability_data", player_name, selected_unit.name, ability.get_index())
				select_ability(null)
			else:
				select_ability(ability)
				
		Enums.TargetType.Position:
			select_ability(ability)
			
		_:
			print("Invalid target type on ability press")


func _unhandled_input(event) -> void:
	if event is InputEventMouseButton && event.pressed:
		var player = get_node(player_name)
		
		if event.button_index == BUTTON_RIGHT:
			if selected_ability:
				select_ability(null)
				
			player.rpc("interrupt")
			
			var movement_path = $Navigation2D.get_simple_path(player.position, event.position)
			$PathDebug.points = movement_path
			$PathDebug.show()
			player.get_node("FollowPathingTimer").stop()
			player.rpc("set_movement_path", movement_path)
			rpc("_set_unit_focus", player_name, "")
			player.rset("auto_attack_enabled", false)
			rpc("_set_unit_queued_ability_data", player_name, null, -1)
			
		elif event.button_index == BUTTON_LEFT:
			if selected_ability && selected_ability.target_type == Enums.TargetType.Position:
				var movement_path = $Navigation2D.get_simple_path(player.position, event.position)
				$PathDebug.points = movement_path
				$PathDebug.show()
				player.rpc("set_movement_path", movement_path)
				rpc("_set_unit_queued_ability_data", player_name, event.position, selected_ability.get_index())
				select_ability(null)
			else:
				select_unit(null)


remotesync func cast_ability_on_unit(ability_index: int, caster_name: String, target_name: String) -> void:
	var caster = get_node(caster_name)
	
	var ability = caster.get_node("Abilities").get_child(ability_index)
	
	if !has_node(target_name):
		print("No target with name: " + target_name)
		
	var target = get_node(target_name)
	caster.cast(ability, target)


func setup(player_name: String, player_lookup: Dictionary) -> void:
	self.player_name = player_name
	
	#TEST ENEMY
	$Enemy.set_name($Enemy.name) # set name label
	$Enemy.set_sprite_color(Color.red)
	$Enemy.team = Enums.Team.Enemy
	$Enemy.set_health_bar_color(Color.red)
	$Enemy.connect("left_clicked", self, "_on_unit_left_clicked", [$Enemy])
	$Enemy.connect("right_clicked", self, "_on_unit_right_clicked", [$Enemy])
	$Enemy.connect("follow_path_outdated", self, "_on_enemy_follow_path_outdated", [$Enemy])
	$Enemy.connect("damage_received", self, "_on_unit_damage_received", [$Enemy])
	$Enemy.connect("healing_received", self, "_on_unit_healing_received", [$Enemy])
	$Enemy.connect("status_effect_applied", self, "_on_unit_status_effect_applied", [$Enemy])
	$Enemy.connect("status_effect_removed", self, "_on_unit_status_effect_removed", [$Enemy])
	$Enemy.connect("team_changed", self, "_on_unit_team_changed", [$Enemy])
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
		unit.team = Enums.Team.Ally
		unit.set_health_bar_color(Color.green)
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
		unit.connect("team_changed", self, "_on_unit_team_changed", [unit])
		
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
			unit.connect("ability_cooldown_started", self, "_on_ability_cooldown_started")
			unit.connect("ability_cooldown_ended", self, "_on_ability_cooldown_ended")
			unit.connect("ability_cooldown_progressed", self, "_on_ability_cooldown_progressed")
			
			for ability in unit.get_node("Abilities").get_children():
				var action_bar_button = _create_action_button(ability.name, ability.icon, Enums.ActionSource.Ability, ability.get_index(), Enums.ButtonSource.ActionBar)
				$CanvasLayer/ActionBar.add_action_button(action_bar_button)
				
				var spellbook_button = _create_action_button(ability.name, ability.icon, Enums.ActionSource.Ability, ability.get_index(), Enums.ButtonSource.Spellbook)
				$CanvasLayer/Spellbook.add_action_button(spellbook_button)
			
			$CanvasLayer/ActionBar.set_max_health(unit.health_attr.value)
			$CanvasLayer/ActionBar.set_max_mana(unit.mana_attr.value)
			$CanvasLayer/CharacterPanel.set_character_name(player_name)
			$CanvasLayer/CharacterPanel.set_character_image(unit.get_node("Sprite").texture)
			$CanvasLayer/CharacterPanel.set_health_attr(unit.health_attr.value)
			$CanvasLayer/CharacterPanel.set_mana_attr(unit.mana_attr.value)
			$CanvasLayer/CharacterPanel.set_attack_power_attr(unit.attack_power_attr.value)
			$CanvasLayer/CharacterPanel.set_spell_power_attr(unit.spell_power_attr.value)
			$CanvasLayer/CharacterPanel.set_movement_speed_attr(unit.movement_speed_attr.value)
			
			$CanvasLayer/Bag.connect("button_dropped_in_slot", self, "_on_Bag_button_dropped_in_slot")
			$CanvasLayer/Bag.connect("button_dropped_on_button", self, "_on_Bag_button_dropped_on_button")
			
			$CanvasLayer/ActionBar.connect("button_dropped_in_slot", self, "_on_ActionBar_button_dropped_in_slot")
			$CanvasLayer/ActionBar.connect("button_dropped_on_button", self, "_on_ActionBar_button_dropped_on_button")
			
#			var item_ability = unit.get_node("Inventory").get_child(0).get_ability()
#			var icon = item_ability.icon # This should probably be the icon from the item, not the ability
#			var action_lookup = ActionLookup.new(Enums.ActionSource.Inventory, item_ability.get_index())
#			$CanvasLayer/Inventory.add_item(icon).connect("clicked", self, "_on_ability_button_clicked", [action_lookup])
			
			# PATHING TEST #
#			$Enemy.rset("focus", unit)
#			var movement_path = $Navigation2D.get_simple_path($Enemy.position, unit.position)
#			$Enemy.rset("auto_attack_enabled", false)
#			$Enemy.rpc("set_movement_path", movement_path)
#			$Enemy.get_node("FollowPathingTimer").start(1.0)
#			$Enemy.movement_speed_attr.push_modifier(Modifier.new(0.5, Enums.ModifierType.Multiplicative))
			# PATHING TEST #
			
		spawn_index += 1


func select_unit(unit: Unit) -> void:
	if unit:
		selected_unit = unit
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


func select_ability(ability: Ability) -> void:
	# Deselect any currently selected ability buttons
	if selected_ability:
		for action_button in _get_action_buttons_by_action_name(selected_ability.name):
			action_button.darken()
				
	if !ability:
		selected_ability = null
		Input.set_custom_mouse_cursor(null)
		return
		
	if get_node(player_name).current_mana < ability.cost:
		print("Insufficient mana")
		return
		
	if ability.is_on_cooldown():
		print("Ability is on cooldown")
		return
	
	selected_ability = ability
	for action_button in _get_action_buttons_by_action_name(selected_ability.name):
		action_button.lighten()
		
	Input.set_custom_mouse_cursor(rainbow_cursor)


remotesync func _set_unit_focus(unit_name: String, focus_name: String) -> void:
	var unit = get_node(unit_name)
	var focus = get_node(focus_name) if focus_name else null
	
	unit.focus = focus


remotesync func _set_unit_queued_ability_data(unit_name: String, target, ability_index: int) -> void:
	if ability_index == -1:
		get_node(unit_name).queued_ability_data = []
	else:
		var adjusted_target = get_node(target) if target is String else target
		get_node(unit_name).queued_ability_data = [ ability_index, adjusted_target ]


# TODO: Does this actually need a name?
func _create_action_button(action_name: String, icon: Texture, action_source: int, action_index: int, button_source: int) -> ActionButton:
	var action_button = action_button_scene.instance()
	action_button.action_name = action_name
	action_button.set_icon(icon)
	action_button.action_lookup = ActionLookup.new(action_source, action_index)
	action_button.source = button_source
	action_button.add_to_group("action_buttons")
	
	action_button.connect("mouse_entered", self, "_on_ability_button_mouse_entered", [action_button])
	action_button.connect("mouse_exited", self, "_on_ability_button_mouse_exited", [action_button])
	action_button.connect("pressed", self, "_on_ability_button_pressed", [action_button])
	action_button.connect("dragged", self, "_on_ability_button_dragged")
	
	return action_button


func _pursue_target(target_name: String) -> void:
	var player = get_node(player_name)
	var movement_path = $Navigation2D.get_simple_path(player.position, get_node(target_name).position)
	$PathDebug.points = movement_path
	$PathDebug.show()
	rpc("_set_unit_focus", player_name, target_name)
	player.rpc("set_movement_path", movement_path)
	player.get_node("FollowPathingTimer").start(1.0)
	
	if get_node(target_name).team != player.team:
		player.rset("auto_attack_enabled", true)


func _get_action_buttons_by_action_name(ability_name: String) -> Array:
	var result = []
	
	for action_button in get_tree().get_nodes_in_group("action_buttons"):
		if action_button.action_name == ability_name:
			result.push_back(action_button)
				
	return result


func _is_team_target_valid(ability: Ability, target) -> bool:
	# If ability targets a unit and the target is a unit of a different team to the ability target team
	return !(typeof(target) == TYPE_OBJECT && target.get_type() == "Unit" && ability.target_type == Enums.TargetType.Unit && ability.target_team != target.team)
