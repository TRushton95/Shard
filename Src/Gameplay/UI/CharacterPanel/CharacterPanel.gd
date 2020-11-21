extends TextureRect

var held := false


func _on_GrabBox_button_down() -> void:
	held = true


func _on_GrabBox_button_up() -> void:
	held = false


func _input(event) -> void:
	if event is InputEventMouseMotion && held:
		rect_position += event.relative


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
