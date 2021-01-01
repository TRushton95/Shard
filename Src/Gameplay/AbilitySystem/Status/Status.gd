extends Node
class_name Status

var _owner_id := -1
var is_debuff := false
var icon_texture: Texture
var duration := 0.0
var tick_rate := 0.0

var damage_per_tick := 0
var healing_per_tick := 0
var health_modifier : Modifier
var mana_modifier : Modifier
var attack_power_modifier : Modifier
var spell_power_modifier : Modifier
var movement_speed_modifier : Modifier

var stopwatch : Stopwatch

signal expired


func _on_stopwatch_tick():
	if damage_per_tick > 0:
		if get_tree().is_network_server():
			get_owner().rpc("damage", damage_per_tick, name, _owner_id)
	
	if healing_per_tick > 0:
		if get_tree().is_network_server():
			get_owner().rpc("heal", healing_per_tick, name, _owner_id)


func _on_stopwatch_timeout():
	if duration == Constants.INDEFINITE_DURATION:
		stopwatch.start()
	else:
		emit_signal("expired")


func _init(owner_id: int) -> void:
	_owner_id = owner_id


func on_apply() -> void:
	if health_modifier:
		get_owner().health_attr.push_modifier(health_modifier)
	if mana_modifier:
		get_owner().mana_attr.push_modifier(mana_modifier)
	if attack_power_modifier:
		get_owner().attack_power_attr.push_modifier(attack_power_modifier)
	if spell_power_modifier:
		get_owner().spell_power_attr.push_modifier(spell_power_modifier)
	if movement_speed_modifier:
		get_owner().movement_speed_attr.push_modifier(movement_speed_modifier)


func on_remove() -> void:
	if health_modifier:
		get_owner().health_attr.remove_modifier(health_modifier)
	if mana_modifier:
		get_owner().mana_attr.remove_modifier(mana_modifier)
	if attack_power_modifier:
		get_owner().attack_power_attr.remove_modifier(attack_power_modifier)
	if spell_power_modifier:
		get_owner().spell_power_attr.remove_modifier(spell_power_modifier)
	if movement_speed_modifier:
		get_owner().movement_speed_attr.remove_modifier(movement_speed_modifier)


func _ready() -> void:
	if duration > 0:
		stopwatch = Stopwatch.new()
		
		var adjusted_duration = tick_rate if duration == Constants.INDEFINITE_DURATION else duration
		stopwatch.setup(adjusted_duration, tick_rate)
		add_child(stopwatch)
		stopwatch.connect("tick", self, "_on_stopwatch_tick")
		stopwatch.connect("timeout", self, "_on_stopwatch_timeout")
		stopwatch.start()


func restart() -> void:
	if !stopwatch:
		print("Cannot restart uninitialised stopwatch")
		return
		
	stopwatch.start()


func get_time_remaining() -> float:
	var result = -1.0
	
	if stopwatch:
		result = stopwatch.get_time_remaining()
		
	return result


func to_data() -> Dictionary:
	return {
		"name": name,
		"owner_id": _owner_id,
		"icon_texture": icon_texture.resource_path if icon_texture else "",
		"is_debuff": is_debuff,
		"duration": duration,
		"tick_rate": tick_rate,
		"damage_per_tick": damage_per_tick,
		"healing_per_tick": healing_per_tick,
		"health_modifier": _modifier_to_data(health_modifier),
		"mana_modifier": _modifier_to_data(mana_modifier),
		"attack_power_modifier": _modifier_to_data(attack_power_modifier),
		"spell_power_modifier": _modifier_to_data(spell_power_modifier),
		"movement_speed_modifier": _modifier_to_data(movement_speed_modifier)
	}


func _modifier_to_data(modifier: Modifier) -> Dictionary:
	var result = null
	
	if modifier:
		result = {
			"value": modifier.value,
			"modifier_type": modifier.modifier_type
		}
		
	return result
