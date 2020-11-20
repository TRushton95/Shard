extends TextureRect


func set_max_health(max_health: int) -> void:
	$HealthBar.max_value = max_health
	_set_health_label($HealthBar.value, max_health)


func set_max_mana(max_mana: int) -> void:
	$ManaBar.max_value = max_mana
	_set_mana_label($ManaBar.value, max_mana)


func set_current_health(health: int) -> void:
	$HealthBar.value = health
	_set_health_label(health, $HealthBar.max_value)


func set_current_mana(mana: int) -> void:
	$ManaBar.value = mana
	_set_mana_label(mana, $ManaBar.max_value)


func set_name(name: String) -> void:
	$NameLabel.text = name


func set_image(texture: Texture) -> void:
	$Image.texture = texture


func _set_health_label(value: int, max_value: int) -> void:
	$HealthBar/MarginContainer/Label.text = str(value) + " / " + str(max_value)
	
	
func _set_mana_label(value: int, max_value: int) -> void:
	$ManaBar/MarginContainer/Label.text = str(value) + " / " + str(max_value)
