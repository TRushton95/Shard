extends TextureRect


func set_max_health(max_health: int) -> void:
	$Health.max_value = max_health


func set_max_mana(max_mana: int) -> void:
	$Health.max_value = max_mana


func set_current_health(health: int) -> void:
	$Health.value = health


func set_current_mana(mana: int) -> void:
	$Mana.value = mana


func initialise(max_health: int, max_mana: int) -> void:
	$Health.max_value = max_health
	$Health.value = max_health
	$Mana.max_value = max_mana
	$Mana.value = max_mana
