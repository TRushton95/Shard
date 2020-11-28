extends TextureButton

var ability_name: String
var _active := false
var _is_hovered := false


func _on_AbilityButton_mouse_entered() -> void:
	_is_hovered = true
	$HoverTexture.show()


func _on_AbilityButton_mouse_exited() -> void:
	_is_hovered = false
	if !_active:
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


func set_unaffordable_filter_visibility(show: bool) -> void:
	if show:
		$UnaffordableTexture.show()
	else:
		$UnaffordableTexture.hide()


func set_active(value: bool) -> void:
	_active = value
	
	if _active:
		$HoverTexture.show()
	elif !_is_hovered:
		$HoverTexture.hide()


func lighten() -> void:
	material.set_shader_param("brightness_modifier", 0.25)


func darken() -> void:
	material.set_shader_param("brightness_modifier", 0)
