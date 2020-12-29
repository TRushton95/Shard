extends Node2D

var rainbow_cursor = load("res://pointer.png")
var unit_scene = load("res://Gameplay/Entities/Unit/Unit.tscn")
var floating_text_scene = load("res://Gameplay/UI/FloatingText/FloatingText.tscn")
var action_button_scene = load("res://Gameplay/UI/ActionButton/ActionButton.tscn")

var player : Unit
var player_name : String
var selected_unit : Unit
var selected_action_lookup : ActionLookup
var force_dragged_button : ActionButton
var force_dragged_button_clone


#This should hook into whatever mechanism determines when an ability key is clicked
func _on_action_button_pressed(button: ActionButton) -> void:
	process_ability_press(button.action_lookup)


func _on_action_button_mouse_entered(button: ActionButton) -> void:
	if button.action_lookup.source == Enums.ActionSource.Spell:
		var ability = player.get_node("Abilities").get_child(button.action_lookup.index)
		
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


func _on_action_button_mouse_exited(button: ActionButton) -> void:
	$CanvasLayer/Tooltip.hide()


func _on_action_button_dragged() -> void:
	$CanvasLayer/Tooltip.hide()


func _on_Bag_button_dropped_in_slot(button: ActionButton, slot: ButtonSlot) -> void:
	match button.source:
		Enums.ButtonSource.Bag:
			var from_index = $CanvasLayer/Bag.get_button_index(button)
			var to_index = slot.get_index()
			$CanvasLayer/Bag.move(from_index, to_index)
			player.get_node("Inventory").move(from_index, to_index)


func _on_Bag_button_dropped_on_button(dropped_button: ActionButton, target_button: ActionButton) -> void:
	match dropped_button.source:
		Enums.ButtonSource.Bag:
			var from_index = $CanvasLayer/Bag.get_button_index(dropped_button)
			var to_index = $CanvasLayer/Bag.get_button_index(target_button)
			$CanvasLayer/Bag.move(from_index, to_index)
			player.get_node("Inventory").move(from_index, to_index)


func _on_ActionBar_button_dropped_in_slot(button: ActionButton, slot: ButtonSlot) -> void:
	match button.source:
		Enums.ButtonSource.Bag:
			var clone_button = _create_action_button(button.action_name, button.texture_normal, button.action_lookup.source, button.action_lookup.index, Enums.ButtonSource.ActionBar)
			slot.add_button(clone_button)
			
		Enums.ButtonSource.Spellbook:
			var clone_button = _create_action_button(button.action_name, button.texture_normal, button.action_lookup.source, button.action_lookup.index, Enums.ButtonSource.Spellbook)
			slot.add_button(clone_button)
			
		Enums.ButtonSource.ActionBar:
			var from_index = $CanvasLayer/ActionBar.get_button_index(button)
			var to_index = slot.get_index()
			$CanvasLayer/ActionBar.move(from_index, to_index)


func _on_ActionBar_button_dropped_on_button(dropped_button: ActionButton, target_button: ActionButton) -> void:
	var from_index = $CanvasLayer/ActionBar.get_button_index(dropped_button)
	var to_index = $CanvasLayer/ActionBar.get_button_index(target_button)
	$CanvasLayer/ActionBar.move(from_index, to_index)
	target_button.start_force_drag()


func _on_unit_left_clicked(unit: Unit) -> void:
	if selected_action_lookup && selected_action_lookup.is_valid():
		rpc("_unit_cast", player_name, selected_action_lookup.source, selected_action_lookup.index, unit.name)
		select_unit(unit)
		select_ability(null)
	else:
		select_unit(unit)


func _on_unit_right_clicked(unit: Unit) -> void:
	if unit != player && unit.team != player.team:
		rpc("_unit_attack_target", player_name, unit.name)


func _on_player_path_set(path: PoolVector2Array) -> void:
	if path && path.size() > 0:
		$PathDebug.points = path
		$PathDebug.show()
	else:
		$PathDebug.hide()


func _on_player_path_finished() -> void:
	$PathDebug.hide()


func _on_unit_status_effect_applied(status_effect: Status, unit: Unit) -> void:
	if unit == player:
		$CanvasLayer/StatusEffectBar.add_status_effect(status_effect)
	
	if unit == selected_unit:
		$CanvasLayer/TargetFrame.add_status_effect(status_effect)


func _on_unit_status_effect_removed(_status_effect: Status, index: int, unit: Unit) -> void:
	if unit == player:
		$CanvasLayer/StatusEffectBar.remove_status_effect(index)
	
	if unit == selected_unit:
		$CanvasLayer/TargetFrame.remove_status_effect(index)


func _on_player_health_attr_changed(value: int) -> void:
	$CanvasLayer/CharacterPanel.set_health_attr(value)
	$CanvasLayer/ActionBar.set_max_health(value)
	
	if selected_unit == player:
		$CanvasLayer/TargetFrame.set_max_health(value)


func _on_player_mana_attr_changed(value: int) -> void:
	$CanvasLayer/CharacterPanel.set_mana_attr(value)
	$CanvasLayer/ActionBar.set_max_mana(value)
	
	if selected_unit == player:
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
		
	if unit == player:
		$CanvasLayer/ActionBar.set_current_health(unit.current_health)


func _on_unit_healing_received(value: int, unit: Unit) -> void:
	var floating_text = floating_text_scene.instance()
	floating_text.setup(value, unit.position, Color.green)
	add_child(floating_text)
	
	if unit == selected_unit:
		$CanvasLayer/TargetFrame.set_current_health(unit.current_health)
		
	if unit == player:
		$CanvasLayer/ActionBar.set_current_health(unit.current_health)


func _on_unit_mana_changed(_value: int, unit: Unit) -> void:
	if unit == selected_unit:
		$CanvasLayer/TargetFrame.set_current_mana(unit.current_mana)
	
	if unit == player:
		$CanvasLayer/ActionBar.set_current_mana(unit.current_mana)
			
		for ability in unit.get_node("Abilities").get_children():
			for action_button in _get_action_buttons_by_action_name(ability.name):
				action_button.set_unaffordable_filter_visibility(unit.current_mana < ability.cost)


func _on_unit_casting_started(ability_name: String, duration: float, unit: Unit) -> void:
	if unit == player && duration > 0.0:
		$CanvasLayer/CastBar.initialise(ability_name, duration)
		$CanvasLayer/CastBar.show()
		
		for action_button in _get_action_buttons_by_action_name(ability_name):
			action_button.set_active(true)


func _on_unit_casting_progressed(time_elapsed: float, unit: Unit) -> void:
	if unit == player:
		$CanvasLayer/CastBar.set_value(time_elapsed)


func _on_unit_casting_stopped(ability_name: String, unit: Unit) -> void:
	if unit == player:
		$CanvasLayer/CastBar.hide()
		
	for action_button in _get_action_buttons_by_action_name(ability_name):
		action_button.set_active(false)


func _on_unit_channelling_started(ability_name: String, channel_time: float, unit: Unit) -> void:
	if unit == player:
		$CanvasLayer/CastBar.initialise(ability_name, channel_time)
		$CanvasLayer/CastBar.show()
		
		for action_button in _get_action_buttons_by_action_name(ability_name):
			action_button.set_active(true)


func _on_unit_channelling_progressed(time_remaining: float, unit: Unit) -> void:
	if unit == player:
		$CanvasLayer/CastBar.set_value(time_remaining)


func _on_unit_channelling_stopped(ability_name: String, unit: Unit) -> void:
	if unit == player:
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
	if unit.team == player.team:
		unit.set_health_bar_color(Color.green)
	else:
		unit.set_health_bar_color(Color.red)


func _process(_delta: float) -> void:
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
		elif selected_action_lookup && selected_action_lookup.is_valid():
			select_ability(null)
	
	if Input.is_action_just_pressed("toggle_character_panel"):
		$CanvasLayer/CharacterPanel.visible = !$CanvasLayer/CharacterPanel.visible
	if Input.is_action_just_pressed("toggle_spellbook"):
		$CanvasLayer/Spellbook.visible = !$CanvasLayer/Spellbook.visible
	if Input.is_action_just_pressed("toggle_bag"):
		$CanvasLayer/Bag.visible = !$CanvasLayer/Bag.visible
	
	if Input.is_action_just_pressed("force_attack"):
		var auto_attack_ability = player.get_node("Abilities/AutoAttack")
		process_ability_press(auto_attack_ability)
	
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
		if player.is_casting || player.is_channelling:
			rpc("_unit_stop_cast", player_name)
		if player.is_moving:
			rpc("_unit_stop_moving", player_name)
			
	if Input.is_action_just_pressed("test_interrupt"):
		player.rpc("interrupt")
	if Input.is_action_just_pressed("test_mana_refill"):
		player.rset("current_mana", player.mana_attr.value)
	
	if button_index >= 0:
		var pressed_button = $CanvasLayer/ActionBar.get_button(button_index)
		
		if pressed_button:
			process_ability_press(pressed_button.action_lookup)
		
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
	
	if action_lookup.source == Enums.ActionSource.Spell:
		var ability = player.get_node("Abilities").get_child(action_lookup.index)
		result = ability
	elif action_lookup.source == Enums.ActionSource.Inventory:
		var item = player.get_node("Inventory").get_item(action_lookup.index)
		result = item.get_ability()
		
	return result


func process_ability_press(action_lookup: ActionLookup):
	var ability = find_action(action_lookup)
	
	match ability.target_type:
		Enums.TargetType.Self:
				rpc("_unit_cast", player_name, action_lookup.source, action_lookup.index, player_name)
		Enums.TargetType.Unit:
			if selected_unit && ability.autocast_on_target:
				rpc("_unit_cast", player_name, action_lookup.source, action_lookup.index, selected_unit.name)
				select_ability(null)
			else:
				select_ability(action_lookup)
				
		Enums.TargetType.Position:
			select_ability(action_lookup)
			
		_:
			print("Invalid target type on ability press")


func _unhandled_input(event) -> void:
	if event is InputEventMouseButton && event.pressed:
		if event.button_index == BUTTON_RIGHT:
			rpc("_unit_move_to_point", player_name, get_global_mouse_position())
			if selected_action_lookup && selected_action_lookup.is_valid():
				select_ability(null)
			
		elif event.button_index == BUTTON_LEFT:
			if selected_action_lookup && selected_action_lookup.is_valid():
				var ability = find_action(selected_action_lookup)
				
				if ability && ability.target_type == Enums.TargetType.Position:
					rpc("_unit_cast", player_name, selected_action_lookup.source, selected_action_lookup.index, get_global_mouse_position())
					select_ability(null)
			else:
				select_unit(null)


func setup(player_name: String, player_lookup: Dictionary) -> void:
	NavigationHelper.set_nav_instance($Navigation2D)
	
	self.player_name = player_name
	
	#TEST ENEMY
	$Enemy.set_name($Enemy.name) # set name label
	$Enemy.set_sprite_color(Color.red)
	$Enemy.team = Enums.Team.Enemy
	$Enemy.set_health_bar_color(Color.red)
	$Enemy.connect("left_clicked", self, "_on_unit_left_clicked", [$Enemy])
	$Enemy.connect("right_clicked", self, "_on_unit_right_clicked", [$Enemy])
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
	for player_list_entry in player_list:
		var unit = unit_scene.instance()
		unit.set_name(player_list_entry)
		unit.position = $PlayerSpawnPoints.get_node(str(spawn_index)).position
		add_child(unit)
		unit.team = Enums.Team.Ally
		unit.set_health_bar_color(Color.green)
		unit.connect("left_clicked", self, "_on_unit_left_clicked", [unit])
		unit.connect("right_clicked", self, "_on_unit_right_clicked", [unit])
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
		
		if player_list_entry == player_name:
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
			unit.connect("path_set", self, "_on_player_path_set")
			
			player = unit
			
			var camera = Camera2D.new()
			camera.current = true
			unit.add_child(camera)
			
			for ability in unit.get_node("Abilities").get_children():
				if ability.get_index() == 0: # HACK: To leave out basic attack, should add an ability category
					continue
				
				var action_bar_button = _create_action_button(ability.name, ability.icon, Enums.ActionSource.Spell, ability.get_index(), Enums.ButtonSource.ActionBar)
				$CanvasLayer/ActionBar.add_action_button(action_bar_button)
				
				var spellbook_button = _create_action_button(ability.name, ability.icon, Enums.ActionSource.Spell, ability.get_index(), Enums.ButtonSource.Spellbook)
				$CanvasLayer/Spellbook.add_entry(ability.name, spellbook_button)
			
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
			
		spawn_index += 1


func select_unit(unit: Unit) -> void:
	if unit:
		selected_unit = unit
		$CanvasLayer/TargetFrame.set_max_health(unit.health_attr.value)
		$CanvasLayer/TargetFrame.set_max_mana(unit.mana_attr.value)
		$CanvasLayer/TargetFrame.set_current_health(unit.current_health)
		$CanvasLayer/TargetFrame.set_current_mana(unit.current_mana)
		$CanvasLayer/TargetFrame.set_name(unit.name)
		$CanvasLayer/TargetFrame.set_image(unit.icon)
		$CanvasLayer/TargetFrame.clear_status_effects()
		for status_effect in unit.get_node("StatusEffects").get_children():
			$CanvasLayer/TargetFrame.add_status_effect(status_effect)
			
		$CanvasLayer/TargetFrame.show()
	else:
		selected_unit = null
		$CanvasLayer/TargetFrame.hide()


func select_ability(action_lookup: ActionLookup) -> void:
	# Deselect any currently selected ability buttons
	if selected_action_lookup && selected_action_lookup.is_valid():
		var selected_ability = find_action(selected_action_lookup)
		for action_button in _get_action_buttons_by_action_name(selected_ability.name):
			action_button.darken()
				
	if !action_lookup || !action_lookup.is_valid():
		selected_action_lookup = null
		Input.set_custom_mouse_cursor(null)
		return
		
	var ability = find_action(action_lookup)
	if player.current_mana < ability.cost:
		print("Insufficient mana")
		return
		
	if ability.is_on_cooldown():
		print("Ability is on cooldown")
		return
	
	selected_action_lookup = action_lookup
	for action_button in _get_action_buttons_by_action_name(ability.name):
		action_button.lighten()
		
	Input.set_custom_mouse_cursor(rainbow_cursor)


# TODO: Does this actually need a name?
func _create_action_button(action_name: String, icon: Texture, action_source: int, action_index: int, button_source: int) -> ActionButton:
	var action_button = action_button_scene.instance()
	action_button.action_name = action_name
	action_button.set_icon(icon)
	action_button.action_lookup = ActionLookup.new(action_source, action_index)
	action_button.source = button_source
	action_button.add_to_group("action_buttons")
	
	action_button.connect("mouse_entered", self, "_on_action_button_mouse_entered", [action_button])
	action_button.connect("mouse_exited", self, "_on_action_button_mouse_exited", [action_button])
	action_button.connect("pressed", self, "_on_action_button_pressed", [action_button])
	action_button.connect("dragged", self, "_on_action_button_dragged")
	
	return action_button


func _get_action_buttons_by_action_name(ability_name: String) -> Array:
	var result = []
	
	for action_button in get_tree().get_nodes_in_group("action_buttons"):
		if action_button.action_name == ability_name:
			result.push_back(action_button)
				
	return result


remotesync func _unit_cast(unit_name: String, action_source: int, action_index: int, dirty_target) -> void:
	if !dirty_target:
		print("No target provided")
		
	var clean_target = dirty_target if dirty_target is Vector2 else get_node(dirty_target)
	
	var unit = get_node(unit_name)
	var ability = find_action(ActionLookup.new(action_source, action_index))
	unit.cast(ability, clean_target)


remotesync func _unit_move_to_point(unit_name: String, position: Vector2) -> void:
	get_node(unit_name).move_to_point(position)


remotesync func _unit_stop_moving(unit_name: String) -> void:
	get_node(unit_name).stop_moving()


remotesync func _unit_attack_target(unit_name: String, target_name: String) -> void:
	get_node(unit_name).attack_target(get_node(target_name))


remotesync func _unit_stop_cast(unit_name: String) -> void:
	get_node(unit_name).interrupt()

