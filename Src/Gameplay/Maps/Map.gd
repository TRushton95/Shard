extends Node2D

var rainbow_cursor = load("res://pointer.png")
var player_scene = load("res://Gameplay/Entities/Units/Player/Player.tscn")
var floating_text_scene = load("res://Gameplay/UI/FloatingText/FloatingText.tscn")
var action_button_scene = load("res://Gameplay/UI/ActionButton/ActionButton.tscn")

const lag_sim_duration = 2.0

var player : Unit
var player_name : String
var selected_unit : Unit
var selected_action_lookup : ActionLookup
var button_drag_handled := false
var dragging_button : ActionButton
var simulating_lag := false

var world_state := {}
var world_state_buffer := []
var player_states := {}
var prev_world_state_timestamp := 0


func _on_ServerClock_ping_updated(ping: int) -> void:
	$CanvasLayer/MarginContainer/Ping.text = "Ping: " + str(ping) + " ms"


func _on_LagSimTimer_timeout() -> void:
	simulating_lag = false


#This should hook into whatever mechanism determines when an ability key is clicked
func _on_action_button_pressed(button: ActionButton) -> void:
	if button.action_lookup.source == Enums.ActionSource.Inventory:
		var item = player.get_node("Inventory").get_item(button.action_lookup.index)
		if item is Gear:
			print("Equip gear")
	else:
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


func _on_action_button_dragged(button: ActionButton) -> void:
	dragging_button = button
	$CanvasLayer/Tooltip.hide()


func _on_Bag_button_dropped_in_slot(button: ActionButton, slot: ButtonSlot) -> void:
	match button.source:
		Enums.ButtonSource.Bag:
			var from_index = $CanvasLayer/Bag.get_button_index(button)
			var to_index = slot.get_index()
			player.get_node("Inventory").move(from_index, to_index)
		Enums.ButtonSource.Equipment:
			var from_index = $CanvasLayer/CharacterPanel.get_button_index(button)
			var to_index = slot.get_index()
			
			var gear = player.get_node("Equipment").unequip_gear(from_index)
			if gear:
				player.get_node("Inventory").push_item(gear, to_index)
			
	button_drag_handled = true


func _on_Bag_button_dropped_on_button(dropped_button: ActionButton, target_button: ActionButton) -> void:
	match dropped_button.source:
		Enums.ButtonSource.Bag:
			var from_index = $CanvasLayer/Bag.get_button_index(dropped_button)
			var to_index = $CanvasLayer/Bag.get_button_index(target_button)
			player.get_node("Inventory").move(from_index, to_index)
			
	button_drag_handled = true


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
			
	button_drag_handled = true


func _on_ActionBar_button_dropped_on_button(dropped_button: ActionButton, target_button: ActionButton) -> void:
	var from_index = $CanvasLayer/ActionBar.get_button_index(dropped_button)
	var to_index = $CanvasLayer/ActionBar.get_button_index(target_button)
	$CanvasLayer/ActionBar.move(from_index, to_index)
	target_button.start_force_drag()
	
	button_drag_handled = true


func _on_CharacterPanel_button_dropped_in_slot(button: ActionButton, slot: GearButtonSlot) -> void:
	if button.source != Enums.ButtonSource.Bag:
		return
		
	var item_index = $CanvasLayer/Bag.get_button_index(button)
	var item = player.get_node("Inventory").get_item(item_index)
	
	if !item is Gear:
		print("Cannot equip item")
		return
		
	if item.slot != slot.gear_slot_type:
		print("Cannot equip in that slot")
		return
		
	player.get_node("Inventory").pop_item(item_index)
	var success = player.get_node("Equipment").equip_gear(item, slot.gear_slot_type)
	if !success:
		player.get_node("Inventory").push_item(item)
 

func _on_CharacterPanel_button_dropped_on_button(button: ActionButton, target_button: ActionButton) -> void:
	if button.source != Enums.ButtonSource.Bag:
		return
		
	var item_index = $CanvasLayer/Bag.get_button_index(button)
	var item = player.get_node("Inventory").get_item(item_index)
	
	var gear_slot_type = $CanvasLayer/CharacterPanel.get_button_index(target_button)
	
	if !item is Gear:
		print("Cannot equip item")
		return
		
	if item.slot != gear_slot_type:
		print("Cannot equip in that slot")
		return
		
	player.get_node("Inventory").pop_item(item_index)
	var unequipped_gear = player.get_node("Equipment").unequip_gear(gear_slot_type)
	var success = player.get_node("Equipment").equip_gear(item, gear_slot_type)
	
	if !success:
		player.get_node("Inventory").push_item(item)
		
	player.get_node("Inventory").push_item(unequipped_gear, item_index)


func _on_unit_left_clicked(unit: Unit) -> void:
	if selected_action_lookup && selected_action_lookup.is_valid():
		rpc("_unit_cast", player_name, selected_action_lookup.source, selected_action_lookup.index, unit.name)
		select_unit(unit)
		select_ability(null)
	else:
		select_unit(unit)


func _on_unit_right_clicked(unit: Unit) -> void:
	if unit != player && unit.team != player.team:
		if !unit.dead:
			rpc("_unit_attack_target", player_name, unit.name)
		else:
			_unit_move_to_point(player_name, unit.position)


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


func _on_player_combat_entered() -> void:
	print("Entered combat")


func _on_player_combat_exited() -> void:
	print("Exited combat")


func _on_player_gear_equipped(gear: Gear) -> void:
	var button = _create_action_button(gear.display_name, gear.icon, Enums.ActionSource.Equip, gear.get_index(), Enums.ButtonSource.Equipment)
	$CanvasLayer/CharacterPanel.add_action_button(button, gear.slot)


func _on_player_gear_unequipped(gear: Gear) -> void:
	$CanvasLayer/CharacterPanel.remove_action_button(gear.slot)


func _on_player_item_added(item: Item, index: int) -> void:
	var item_button = _create_action_button(item.display_name, item.icon, Enums.ActionSource.Inventory, index, Enums.ButtonSource.Bag)
	$CanvasLayer/Bag.add_action_button(item_button, index)


func _on_player_item_removed(item: Item, index: int) -> void:
	$CanvasLayer/Bag.remove_action_button(index)


func _on_unit_damage_received(value: int, source_id: int, caster_id: int, unit: Unit) -> void:
	var floating_text = floating_text_scene.instance()
	floating_text.setup(value, unit.position, Color.red)
	add_child(floating_text)
	
	if unit == selected_unit:
		$CanvasLayer/TargetFrame.set_current_health(unit.current_health)
		
	if unit == player:
		$CanvasLayer/ActionBar.set_current_health(unit.current_health)


func _on_unit_healing_received(value: int, source_id: int, caster_id: int, unit: Unit) -> void:
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


func _on_ThreatMeter_data_expired():
	$CanvasLayer/ThreatMeter.set_data($Enemy.threat_table)


func _physics_process(delta: float) -> void:
	if get_tree().is_network_server():
		if !player_states.empty():
			world_state = player_states.duplicate(true)
			for player in world_state.keys():
				world_state[player].erase(Constants.Network.TIME)
				
			world_state[Constants.Network.TIME] = OS.get_system_time_msecs()
			_send_world_state(world_state)
			
	var render_time = ServerClock.get_time() - Constants.INTERPOLATION_OFFSET
	if world_state_buffer.size() > 1:
		while world_state_buffer.size() > 2 && world_state_buffer[1][Constants.Network.TIME] < render_time:
			world_state_buffer.remove(0)
			
		var interpolation_factor = (render_time - world_state_buffer[0][Constants.Network.TIME]) / (world_state_buffer[1][Constants.Network.TIME] - world_state_buffer[0][Constants.Network.TIME])
		
		for key in world_state_buffer[1].keys():
			if str(key) == Constants.Network.TIME:
				continue
			if key == get_tree().get_network_unique_id():
				continue
			if !world_state_buffer[0].has(key):
				continue
				
			var user_name = ServerInfo.get_user_name(key)
			if has_node(user_name):
				var new_position = lerp(world_state_buffer[0][key][Constants.Network.POSITION], world_state_buffer[1][key][Constants.Network.POSITION], interpolation_factor)
				get_node(user_name).position = new_position
			else:
				# TODO: Spawn player
				pass


func _process(_delta: float) -> void:
	# Test commands for testing whatever
	if Input.is_action_just_pressed("test_right"):
		player.get_node("Inventory").pop_item(0)
		$CanvasLayer/Bag.remove_action_button(0)
	# End of test commands
	
	if Input.is_action_just_pressed("cancel"):
		var handled = false
		
		if selected_action_lookup && selected_action_lookup.is_valid():
			select_ability(null)
			handled = true
		
		if !handled:
			if $CanvasLayer/CharacterPanel.visible:
				$CanvasLayer/CharacterPanel.visible = false
				handled = true
			if $CanvasLayer/Spellbook.visible:
				$CanvasLayer/Spellbook.visible = false
				handled = true
			if $CanvasLayer/Bag.visible:
				$CanvasLayer/Bag.visible = false
				handled = true
			
		if !handled && selected_unit:
			select_unit(null)
	
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
		rpc("_unit_stop", player_name)
	if Input.is_action_just_pressed("LagSgim"):
		simulating_lag = true
		$LagSimTimer.start(lag_sim_duration)
		
		
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
	if !event is InputEventMouseButton:
		return
		
	if event.pressed:
		if event.button_index == BUTTON_RIGHT:
			_unit_move_to_point(player_name, get_global_mouse_position())
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
				
	else:
		if event.button_index == BUTTON_LEFT:
			if dragging_button:
				if !button_drag_handled:
					match dragging_button.source:
						Enums.ButtonSource.ActionBar:
							var button_index = $CanvasLayer/ActionBar.get_button_index(dragging_button)
							$CanvasLayer/ActionBar.remove_action_button(button_index)
							
				button_drag_handled = false
				dragging_button = null


func setup() -> void:
	NavigationHelper.set_nav_instance($Navigation2D)
	ServerClock.connect("ping_updated", self, "_on_ServerClock_ping_updated")
	
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
	
	var spawn_index = 0
	for user_id in ServerInfo.get_sorted_user_ids():
		var user_name = ServerInfo.get_user_name(user_id)
		
		var unit = player_scene.instance()
		unit.set_name(user_name)
		unit.position = $PlayerSpawnPoints.get_node(str(spawn_index)).position
		add_child(unit)
		unit.team = Enums.Team.Ally
		unit.set_health_bar_color(Color.green)
		unit.set_network_master(user_id)
		
		if user_id == get_tree().get_network_unique_id():
			self.player_name = ServerInfo.get_user_name(user_id)
		
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
		
		if user_name == player_name:
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
			unit.connect("combat_entered", self, "_on_player_combat_entered")
			unit.connect("combat_exited", self, "_on_player_combat_exited")
			unit.connect("gear_equipped", self, "_on_player_gear_equipped")
			unit.connect("gear_unequipped", self, "_on_player_gear_unequipped")
			unit.connect("item_added", self, "_on_player_item_added")
			unit.connect("item_removed", self, "_on_player_item_removed")
			
			player = unit
			
			var camera = Camera2D.new()
			camera.current = true
			unit.add_child(camera)
			
			for ability in unit.get_node("Abilities").get_children():
				ability.setup(unit.get_instance_id())
				
				if ability.get_index() == 0: # HACK: To leave out basic attack, should add an ability category
					continue
				
				var action_bar_button = _create_action_button(ability.name, ability.icon, Enums.ActionSource.Spell, ability.get_index(), Enums.ButtonSource.ActionBar)
				$CanvasLayer/ActionBar.add_action_button(action_bar_button)
				
				var spellbook_button = _create_action_button(ability.name, ability.icon, Enums.ActionSource.Spell, ability.get_index(), Enums.ButtonSource.Spellbook)
				$CanvasLayer/Spellbook.add_entry(ability.name, spellbook_button)
			
			$CanvasLayer/ActionBar.set_max_health(unit.health_attr.value)
			$CanvasLayer/ActionBar.set_max_mana(unit.mana_attr.value)
			$CanvasLayer/CharacterPanel.set_character_name(player_name)
			#$CanvasLayer/CharacterPanel.set_character_image(unit.get_node("TorsoSprite").texture)
			$CanvasLayer/CharacterPanel.set_health_attr(unit.health_attr.value)
			$CanvasLayer/CharacterPanel.set_mana_attr(unit.mana_attr.value)
			$CanvasLayer/CharacterPanel.set_attack_power_attr(unit.attack_power_attr.value)
			$CanvasLayer/CharacterPanel.set_spell_power_attr(unit.spell_power_attr.value)
			$CanvasLayer/CharacterPanel.set_movement_speed_attr(unit.movement_speed_attr.value)
			
			$CanvasLayer/Bag.connect("button_dropped_in_slot", self, "_on_Bag_button_dropped_in_slot")
			$CanvasLayer/Bag.connect("button_dropped_on_button", self, "_on_Bag_button_dropped_on_button")
			
			$CanvasLayer/ActionBar.connect("button_dropped_in_slot", self, "_on_ActionBar_button_dropped_in_slot")
			$CanvasLayer/ActionBar.connect("button_dropped_on_button", self, "_on_ActionBar_button_dropped_on_button")
			
			$CanvasLayer/CharacterPanel.connect("button_dropped_in_slot", self, "_on_CharacterPanel_button_dropped_in_slot")
			$CanvasLayer/CharacterPanel.connect("button_dropped_on_button", self, "_on_CharacterPanel_button_dropped_on_button")
			
			var bronze_chestplate_scene = load("res://Gameplay/Entities/Items/Gear/BronzeChestplate.tscn")
			var bronze_chestplate = bronze_chestplate_scene.instance()
			player.get_node("Inventory").push_item(bronze_chestplate)
			
			var bronze_chestplate_2 = bronze_chestplate_scene.instance()
			bronze_chestplate_2.icon = load("res://Gameplay/Entities/Items/Consumables/icon.png")
			player.get_node("Inventory").push_item(bronze_chestplate_2)
			
#			var fireball_scroll_scene = load("res://Gameplay/Entities/Items/Consumables/FireballScroll.tscn")
#			var fireball_scroll = fireball_scroll_scene.instance()
#			player.get_node("Inventory").push_item(fireball_scroll)
			
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
	action_button.connect("dragged", self, "_on_action_button_dragged", [action_button])
	
	return action_button


func _get_action_buttons_by_action_name(ability_name: String) -> Array:
	var result = []
	
	for action_button in get_tree().get_nodes_in_group("action_buttons"):
		if action_button.action_name == ability_name:
			result.push_back(action_button)
				
	return result


func _send_player_state(player_state: Dictionary) -> void:
	rpc_unreliable_id(Constants.SERVER_ID, "_recieve_player_state", player_state)


master func _recieve_player_state(new_player_state: Dictionary) -> void:
	var sender_id = get_tree().get_rpc_sender_id()
	
	if player_states.has(sender_id):
		if player_states[sender_id][Constants.Network.TIME] < new_player_state[Constants.Network.TIME]:
			player_states[sender_id] = new_player_state
	else:
		player_states[sender_id] = new_player_state


func _send_world_state(world_state: Dictionary) -> void:
	if simulating_lag:
		return
	
	rpc_unreliable_id(Constants.ALL_CONNECTED_PEERS_ID, "_receive_world_state", world_state)


remotesync func _receive_world_state(world_state: Dictionary) -> void:
	if world_state[Constants.Network.TIME] > prev_world_state_timestamp:
		prev_world_state_timestamp = world_state[Constants.Network.TIME]
		world_state_buffer.append(world_state)


remotesync func _unit_cast(unit_name: String, action_source: int, action_index: int, dirty_target) -> void:
	if !dirty_target:
		print("No target provided")
		
	var clean_target = dirty_target if dirty_target is Vector2 else get_node(dirty_target)
	
	if clean_target is Unit && clean_target.dead:
		print("Target is dead")
		return
	
	var unit = get_node(unit_name)
	var ability = find_action(ActionLookup.new(action_source, action_index))
	unit.input_command(CastCommand.new(ability, clean_target))


func _unit_move_to_point(unit_name: String, position: Vector2) -> void:
	get_node(unit_name).input_command(MoveCommand.new(position))


remotesync func _unit_stop(unit_name: String) -> void:
	get_node(unit_name).input_command(StopCommand.new())

remotesync func _unit_attack_target(unit_name: String, target_name: String) -> void:
	get_node(unit_name).input_command(AttackCommand.new(get_node(target_name)))
