extends TextureButton
class_name ActionButton

var action_name: String
var _active := false
var _is_hovered := false
var _mouse_just_pressed := false

var _grab_position := Vector2(-1, -1)
var _grab_threshold := 15
var _grabbed := false

signal grabbed
signal clicked


func _on_ActionButton_mouse_entered() -> void:
	_is_hovered = true
	$ActiveTexture.show()


func _on_ActionButton_mouse_exited() -> void:
	_is_hovered = false
	if !_active:
		$ActiveTexture.hide()


func _on_ActionButton_button_down() -> void:
	_mouse_just_pressed = true
	_grab_position = get_global_mouse_position()


func _on_ActionButton_button_up():
	if !_grabbed:
		emit_signal("clicked")
		
	_grabbed = false
	_grab_position = Vector2(-1, -1)


func _input(event) -> void:
	if event is InputEventMouseMotion && _mouse_just_pressed && _grab_position != Vector2(-1, -1) && event.position.distance_to(_grab_position) > _grab_threshold:
		_mouse_just_pressed = false
		_grabbed = true
		emit_signal("grabbed")


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
		$ActiveTexture.show()
	elif !_is_hovered:
		$ActiveTexture.hide()


func lighten() -> void:
	material.set_shader_param("brightness_modifier", 0.25)


func darken() -> void:
	material.set_shader_param("brightness_modifier", 0)


func get_grab_offset() -> Vector2:
	return _grab_position - rect_position if _grabbed else Vector2.ZERO
