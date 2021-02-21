extends TextureRect

signal button_dropped_in_slot(action_button, slot)
signal button_dropped_on_button(dropped_button, target_button)

var _held := false


func _on_ButtonSlot_button_dropped_on_slot(action_button: ActionButton, slot: ButtonSlot) -> void:
	emit_signal("button_dropped_in_slot", action_button, slot)


func _on_ActionButton_button_dropped_on_button(dropped_button: ActionButton, target_button: ActionButton) -> void:
	emit_signal("button_dropped_on_button", dropped_button, target_button)


func _on_GrabBox_button_down() -> void:
	_held = true


func _on_GrabBox_button_up() -> void:
	_held = false


func _ready() -> void:
	for slot in $GearSlots.get_children():
		slot.connect("button_dropped", self, "_on_ButtonSlot_button_dropped_on_slot", [slot])


func _input(event) -> void:
	if event is InputEventMouseMotion && _held:
		rect_position += event.relative


func add_action_button(action_button: ActionButton, gear_slot: int) -> void:
	var slot
	match gear_slot:
		Enums.GearSlot.HEAD:
			slot = $GearSlots/HeadSlot
		Enums.GearSlot.CHEST:
			slot = $GearSlots/ChestSlot
		Enums.GearSlot.LEGS:
			slot = $GearSlots/LegsSlot
		Enums.GearSlot.FEET:
			slot = $GearSlots/FeetSlot
		Enums.GearSlot.HANDS:
			slot = $GearSlots/HandsSlot
		Enums.GearSlot.RING1:
			slot = $GearSlots/RingSlot1
		Enums.GearSlot.RING2:
			slot = $GearSlots/RingSlot2
		Enums.GearSlot.TRINKET1:
			slot = $GearSlots/TrinketSlot1
		Enums.GearSlot.TRINKET2:
			slot = $GearSlots/TrinketSlot2
		Enums.GearSlot.WEAPON:
			slot = $GearSlots/WeaponSlot
		_:
			return
			
	slot.add_button(action_button)
	action_button.connect("button_dropped", self, "_on_ActionButton_button_dropped_on_button", [action_button])


func remove_action_button(gear_slot: int) -> void:
	var slot
	match gear_slot:
		Enums.GearSlot.HEAD:
			slot = $GearSlots/HeadSlot
		Enums.GearSlot.CHEST:
			slot = $GearSlots/ChestSlot
		Enums.GearSlot.LEGS:
			slot = $GearSlots/LegsSlot
		Enums.GearSlot.FEET:
			slot = $GearSlots/FeetSlot
		Enums.GearSlot.HANDS:
			slot = $GearSlots/HandsSlot
		Enums.GearSlot.RING1:
			slot = $GearSlots/RingSlot1
		Enums.GearSlot.RING2:
			slot = $GearSlots/RingSlot2
		Enums.GearSlot.TRINKET1:
			slot = $GearSlots/TrinketSlot1
		Enums.GearSlot.TRINKET2:
			slot = $GearSlots/TrinketSlot2
		Enums.GearSlot.WEAPON:
			slot = $GearSlots/WeaponSlot
		_:
			return
			
	var action_button = slot.pop_button()
	action_button.queue_free()


func set_character_name(character_name: String) -> void:
	$NameLabel.text = character_name


func set_character_image(texture: Texture) -> void:
	$CharacterImage.texture = texture


func set_health_attr(health: int) -> void:
	$Health/Label.text = str(health)


func set_mana_attr(mana: int) -> void:
	$Mana/Label.text = str(mana)


func set_attack_power_attr(attack_power: int) -> void:
	$AttackPower/Label.text = str(attack_power)


func set_spell_power_attr(spell_power: int) -> void:
	$SpellPower/Label.text = str(spell_power)


func set_movement_speed_attr(movement_speed: int) -> void:
	$MovementSpeed/Label.text = str(movement_speed)
