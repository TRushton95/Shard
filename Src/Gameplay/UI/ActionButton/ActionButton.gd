extends TextureButton
class_name ActionButton

var action_name: String
var action_lookup: ActionLookup
var source := -1

var _active := false
var _is_hovered := false
var _drag_preview : ActionButton
var _force_dragging := false

signal dragged
signal button_dropped


func _on_ActionButton_mouse_entered() -> void:
	_is_hovered = true
	$ActiveTexture.show()


func _on_ActionButton_mouse_exited() -> void:
	_is_hovered = false
	if !_active:
		$ActiveTexture.hide()


func _process(delta: float) -> void:
	if _force_dragging:
		_drag_preview = self.duplicate() # HACK: It's screaming at me without reassigning this every frame
		force_drag(self, _drag_preview)


func _input(event) -> void:
	if event is InputEventMouseButton && event.button_index == BUTTON_LEFT && event.pressed && _force_dragging:
		_force_dragging = false


func get_type() -> String:
	return Constants.ClassNames.ACTION_BUTTON


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


func start_force_drag() -> void:
	_force_dragging = true
	_drag_preview = self.duplicate()


func lighten() -> void:
	material.set_shader_param("brightness_modifier", 0.25)


func darken() -> void:
	material.set_shader_param("brightness_modifier", 0)


func get_drag_data(_position: Vector2):
	var drag_clone = self.duplicate()
	set_drag_preview(drag_clone)
	emit_signal("dragged")
	hide()
	return self


func can_drop_data(_position: Vector2, data) -> bool:
	var result
	
	if data.get_type() == "ActionButton":
		result = true
		
	return result


func drop_data(_position: Vector2, data):
	if data.get_type() == "ActionButton":
		emit_signal("button_dropped", data)
