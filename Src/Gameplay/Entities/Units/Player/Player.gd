extends Unit
class_name Player

signal gear_equipped(gear)
signal gear_unequipped(gear)
signal item_added(item, index)
signal item_removed(item, index)

var default_head_sprite = preload("res://Gameplay/Entities/Units/Player/DefaultSprites/hero_base_head.png")
var default_torso_sprite = preload("res://Gameplay/Entities/Units/Player/DefaultSprites/hero_base_torso.png")
var default_legs_sprite = preload("res://Gameplay/Entities/Units/Player/DefaultSprites/hero_base_legs.png")
var default_feet_sprite = preload("res://Gameplay/Entities/Units/Player/DefaultSprites/hero_base_feet.png")
var default_arms_sprite = preload("res://Gameplay/Entities/Units/Player/DefaultSprites/hero_base_arms.png")
var default_hands_sprite = preload("res://Gameplay/Entities/Units/Player/DefaultSprites/hero_base_hands.png")

var default_torso_animation_type = Enums.UnitAnimationType.IDLE
var default_arms_animation_type = Enums.UnitAnimationType.IDLE
var playing_priority_arms_animation := false
var playing_priority_body_animation := false


func _on_state_entered(state_name: String) -> void:
	match state_name:
		Constants.StateNames.IDLE_NAVIGATION:
			set_default_body_animation_type(Enums.UnitAnimationType.IDLE)
			if !is_casting && !is_channelling:
				set_default_arms_animation_type(Enums.UnitAnimationType.IDLE)
				
		Constants.StateNames.MOVEMENT_NAVIGATION:
			set_default_body_animation_type(Enums.UnitAnimationType.WALKING)
			set_default_arms_animation_type(Enums.UnitAnimationType.WALKING)
			
		Constants.StateNames.PURSUE_NAVIGATION:
			set_default_body_animation_type(Enums.UnitAnimationType.WALKING)
			
		Constants.StateNames.CHANNELLING_COMBAT:
			set_default_arms_animation_type(Enums.UnitAnimationType.CASTING)
			
		Constants.StateNames.IDLE_COMBAT:
			if is_moving:
				set_default_arms_animation_type(Enums.UnitAnimationType.WALKING)
			else:
				set_default_arms_animation_type(Enums.UnitAnimationType.IDLE)


func _on_casting_started(ability: Ability) -> void:
	._on_casting_started(ability)
	
	if ability.cast_time > 0:
		set_default_arms_animation_type(Enums.UnitAnimationType.CASTING)
	elif !"channel_time" in ability:
		var casting_animation = _get_animation_name(Enums.UnitAnimationType.CASTING, direction)
		play_priority_arms_animation(casting_animation)


func _on_ArmsAnimationPlayer_animation_finished(anim_name: String):
	playing_priority_arms_animation = false
	var default_animation = _get_animation_name(default_arms_animation_type, direction)
	$ArmsAnimationPlayer.play(default_animation)
	
	# Sync up with body animation
	var body_animation_position = $BodyAnimationPlayer.current_animation_position
	$BodyAnimationPlayer.seek(body_animation_position, true)


func _on_TorsoAnimationPlayer_animation_finished(anim_name: String):
	playing_priority_body_animation = false
	var default_animation = _get_animation_name(default_torso_animation_type, direction)
	$BodyAnimationPlayer.play(default_animation)
	
	# Sync up with arms animation
	var arms_animation_position = $ArmsAnimationPlayer.current_animation_position
	$BodyAnimationPlayer.seek(arms_animation_position, true)


func _on_Equipment_item_equipped(gear: Gear) -> void:
	if gear.health_stat > 0:
		health_attr.push_modifier(gear.health_modifier)
	if gear.mana_stat > 0:
		mana_attr.push_modifier(gear.mana_modifier)
	if gear.attack_power_stat > 0:
		attack_power_attr.push_modifier(gear.attack_power_modifier)
	if gear.spell_power_stat > 0:
		spell_power_attr.push_modifier(gear.spell_power_modifier)
	if gear.movement_speed_stat > 0:
		movement_speed_attr.push_modifier(gear.movement_speed_modifier)
		
	if gear is HeadGear:
		$HeadSprite.texture = gear.sprite
	elif gear is ChestGear:
		$ChestSprite.texture = gear.torso_sprite
		$ArmsSprite.texture = gear.arms_sprite
	elif gear is LegsGear:
		$LegsSprite.texture = gear.sprite
	elif gear is FeetGear:
		$FeetSprite.texture = gear.sprite
	elif gear is HandsGear:
		$HandsSprite.texture = gear.sprite
		
	emit_signal("gear_equipped", gear)


func _on_Equipment_item_unequipped(gear: Gear) -> void:
	if gear.health_stat > 0:
		health_attr.remove_modifier(gear.health_modifier)
	if gear.mana_stat > 0:
		mana_attr.remove_modifier(gear.mana_modifier)
	if gear.attack_power_stat > 0:
		attack_power_attr.remove_modifier(gear.attack_power_modifier)
	if gear.spell_power_stat > 0:
		spell_power_attr.remove_modifier(gear.spell_power_modifier)
	if gear.movement_speed_stat > 0:
		movement_speed_attr.remove_modifier(gear.movement_speed_modifier)
	
	if gear is HeadGear:
		$HeadSprite.texture = default_head_sprite
	elif gear is ChestGear:
		$ChestSprite.texture = default_torso_sprite
		$ArmsSprite.texture = default_arms_sprite
	elif gear is LegsGear:
		$LegsSprite.texture = default_legs_sprite
	elif gear is FeetGear:
		$FeetSprite.texture = default_feet_sprite
	elif gear is HandsGear:
		$HandsSprite.texture = default_hands_sprite
		
	emit_signal("gear_unequipped", gear)


func _on_Inventory_item_added(item: Item, index: int) -> void:
	emit_signal("item_added", item, index)


func _on_Inventory_item_removed(item: Item, index: int) -> void:
	emit_signal("item_removed", item, index)


func _on_Inventory_item_moved(item1: Item, index1: int, item2: Item, index2: int) -> void:
	emit_signal("item_moved", item1, index1, item2, index2)


func _on_Player_died() -> void:
	if playing_priority_body_animation:
		play_priority_body_animation("dead")
		
	if playing_priority_arms_animation:
		play_priority_arms_animation("dead")
	
	set_default_body_animation_type(Enums.UnitAnimationType.DEAD)
	set_default_arms_animation_type(Enums.UnitAnimationType.DEAD)


func _ready() -> void:
	# super class called by default
	set_default_body_animation_type(Enums.UnitAnimationType.IDLE)
	set_default_arms_animation_type(Enums.UnitAnimationType.IDLE)
	
	$ArmsAnimationPlayer.connect("animation_finished", self, "_on_ArmsAnimationPlayer_animation_finished")
	$BodyAnimationPlayer.connect("animation_finished", self, "_on_TorsoAnimationPlayer_animation_finished")
	
	$Equipment.connect("item_equipped", self, "_on_Equipment_item_equipped")
	$Equipment.connect("item_unequipped", self, "_on_Equipment_item_unequipped")
	$Inventory.connect("item_added", self, "_on_Inventory_item_added")
	$Inventory.connect("item_removed", self, "_on_Inventory_item_removed")


func change_direction(new_direction: int) -> void:
	.change_direction(new_direction)
	
	var direction_name = Direction.keys()[direction].to_lower() # FIXME: Do this properly
	
	var current_torso_animation_type = get_body_animation_name().split("_")[0]
	var current_torso_animation_position = get_body_animation_position()
	
	var full_torso_animation_name = current_torso_animation_type + "_" + direction_name
	$BodyAnimationPlayer.play(full_torso_animation_name)
	$BodyAnimationPlayer.seek(current_torso_animation_position, true)
	
	var current_arms_animation_type = get_arms_animation_name().split("_")[0]
	var current_arms_animation_position = get_arms_animation_position()
	
	var full_arms_animation_name = current_arms_animation_type + "_" + direction_name
	$ArmsAnimationPlayer.play(full_arms_animation_name)
	$ArmsAnimationPlayer.seek(current_arms_animation_position, true)


func get_arms_animation_name() -> String:
	return $ArmsAnimationPlayer.current_animation


func get_arms_animation_position() -> float:
	return $ArmsAnimationPlayer.current_animation_position


func get_body_animation_name() -> String:
	return $BodyAnimationPlayer.current_animation


func get_body_animation_position() -> float:
	return $BodyAnimationPlayer.current_animation_position


func _set_arms_animation_type_looping(animation_type: int, loop: bool) -> void:
	for value in Direction.values():
		var animation = _get_animation_name(animation_type, value)
		$ArmsAnimationPlayer.get_animation(animation).set_loop(loop)


func _set_torso_animation_type_looping(animation_type: int, loop: bool) -> void:
	for value in Direction.values():
		var default_animation = _get_animation_name(animation_type, value)
		$BodyAnimationPlayer.get_animation(default_animation).set_loop(loop)


func set_default_arms_animation_type(anim_type) -> void:
	_set_arms_animation_type_looping(default_arms_animation_type, false)
	default_arms_animation_type = anim_type
	_set_arms_animation_type_looping(default_arms_animation_type, true)
	
	if !playing_priority_arms_animation:
		var default = _get_animation_name(default_arms_animation_type, direction)
		#FIXME: This seems to be playing the previous direction, direction not updated yet at this point?
		$ArmsAnimationPlayer.play(default)


func set_default_body_animation_type(anim_type) -> void:
	_set_torso_animation_type_looping(default_torso_animation_type, false)
	default_torso_animation_type = anim_type
	_set_torso_animation_type_looping(default_torso_animation_type, true)
		
	if !playing_priority_body_animation:
		var default = _get_animation_name(default_torso_animation_type, direction)
		$BodyAnimationPlayer.play(default)


func play_priority_arms_animation(anim_name: String, position := 0.0) -> void:
	playing_priority_arms_animation = true
	$ArmsAnimationPlayer.play(anim_name)
	
	if position > 0.0:
		$ArmsAnimationPlayer.seek(position, true)


func play_priority_body_animation(anim_name: String, position := 0.0) -> void:
	playing_priority_body_animation = true
	$BodyAnimationPlayer.play(anim_name)
	
	if position > 0.0:
		$BodyAnimationPlayer.seek(position, true)


func _play_on_enter_casting_combat_animation(ability: Ability) -> void:
	if ability.cast_time > 0:
		set_default_arms_animation_type(Enums.UnitAnimationType.CASTING)
	elif !"channel_time" in ability:
		var casting_animation = _get_animation_name(Enums.UnitAnimationType.CASTING, direction)
		play_priority_arms_animation(casting_animation)
