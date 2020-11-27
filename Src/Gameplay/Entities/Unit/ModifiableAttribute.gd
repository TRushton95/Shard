extends Node
class_name ModifiableAttribute

var base_value : float setget set_base_value
var value : float setget set_value, get_value
var _modifiers := []
var _is_dirty := true


signal changed(value)


func _init(base_value: float) -> void:
	self.base_value = base_value


# Now that attribute change is being emitted, is _is_dirty flag needed anymore? Don't think so
func get_value() -> float:
	if _is_dirty:
		value = base_value
		
		for modifier in _modifiers:
			if modifier.modifier_type == Enums.ModifierType.Additive:
				value += modifier.value
			elif modifier.modifier_type == Enums.ModifierType.Multiplicative:
				value *= modifier.value
				
		_is_dirty = false
		
	return value


func set_value(_value: float) -> void:
	print("Attribute value cannot be set directly")


func set_base_value(value: float) -> void:
	base_value = value
	_is_dirty = true
	emit_signal("changed", get_value())

func push_modifier(modifier: Modifier) -> void:
	_modifiers.push_back(modifier)
	_is_dirty = true
	emit_signal("changed", get_value())


func remove_modifier(modifier: Modifier) -> void:
	_modifiers.erase(modifier)
	_is_dirty = true
	emit_signal("changed", get_value())


func get_display_text() -> String:
	return str(stepify(value, 1))
