extends TextureButton
class_name ActionButton

var action_name: String
var _original_position : Vector2
var _active := false
var _is_hovered := false
var _mouse_down := false
var _is_held := false
var _mouse_offset

signal clicked
signal held
signal unheld


func _on_ActionButton_mouse_entered() -> void:
	_is_hovered = true
	$ActiveTexture.show()


func _on_ActionButton_mouse_exited() -> void:
	_is_hovered = false
	if !_active:
		$ActiveTexture.hide()


func _on_ActionButton_button_down() -> void:
	_mouse_down = true


func _on_ActionButton_button_up() -> void:
	if !_is_held:
		emit_signal("clicked")
	
	_mouse_down = false
	
	if _is_held:
		_is_held = false
		emit_signal("unheld")


func _ready() -> void:
	add_to_group("action_buttons")


func _input(event) -> void:
	if event is InputEventMouseMotion:
		if _mouse_down && !_is_held:
			_mouse_offset = event.position - rect_global_position
			_is_held = true
			_original_position = rect_position
			emit_signal("held")
			
		if _is_held:
			rect_global_position = event.position - _mouse_offset


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


func reset_position() -> void:
	rect_position = _original_position


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
