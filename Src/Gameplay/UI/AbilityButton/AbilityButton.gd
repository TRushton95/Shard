extends TextureButton

var ability_name: String


func _on_AbilityButton_mouse_entered() -> void:
	$HoverTexture.show()


func _on_AbilityButton_mouse_exited() -> void:
	$HoverTexture.hide()


func _ready() -> void:
	add_to_group("ability_buttons")


func set_icon(icon: Texture) -> void:
	texture_normal = icon


func set_max_cooldown(value: float) -> void:
	$CooldownTexture.max_value = value


func show_cooldown() -> void:
	$CooldownTexture.show()
	$CooldownLabel.show()


func hide_cooldown() -> void:
	$CooldownTexture.hide()
	$CooldownLabel.hide()


func set_cooldown(value: float) -> void:
	$CooldownTexture.value = value
	$CooldownLabel.text = str(ceil(value))


func lighten() -> void:
	material.set_shader_param("brightness_modifier", 0.25)


func darken() -> void:
	material.set_shader_param("brightness_modifier", 0)
