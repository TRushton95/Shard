extends TextureButton


func _on_AbilityButton_mouse_entered() -> void:
	$HoverTexture.show()


func _on_AbilityButton_mouse_exited() -> void:
	$HoverTexture.hide()


func set_icon(icon: Texture) -> void:
	texture_normal = icon


func set_max_cooldown(value: float) -> void:
	$CooldownTexture.max_value = value


func set_cooldown(value: float) -> void:
	$CooldownTexture.value = value
	$CooldownLabel.text = str(ceil(value))
