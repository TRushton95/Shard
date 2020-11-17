extends Node
class_name ModifiableAttribute

var base_value : float
var value : float setget set_value, get_value
var _modifiers := []
var _is_dirty := true


func _init(base_value: float) -> void:
	self.base_value = base_value


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


func set_value(value: float) -> void:
	print("Attribute value cannot be set directly")


func push_modifier(modifier: Modifier) -> void: # should be class that indicates additive or multiplicative and value
	_modifiers.push_back(modifier)
	_is_dirty = true


func remove_modifier(modifier: Modifier) -> void: # should be class that indicates additive or multiplicative and value
	_modifiers.erase(modifier)
	_is_dirty = true


func get_display_text() -> String:
	return str(stepify(value, 1))
