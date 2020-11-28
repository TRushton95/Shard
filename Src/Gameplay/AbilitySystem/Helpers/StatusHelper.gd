extends Node


func dot(damage_per_tick: int, duration: float, tick_rate: float, icon_texture_path: String, status_name: String) -> Status:
	var result = Status.new(true, duration, icon_texture_path)
	result.icon_texture_path = icon_texture_path
	result.damage_per_tick = damage_per_tick
	result.tick_rate = tick_rate
	result.name = status_name
	
	return result


func build_from_data(data: Dictionary) -> Status:
	var status_name = data["name"]
	var icon_texture_path = data["icon_texture_path"]
	var is_debuff = data["is_debuff"]
	var duration = data["duration"]
	var tick_rate = data["tick_rate"]
	var damage_per_tick = data["damage_per_tick"]
	var healing_per_tick = data["healing_per_tick"]
	var health_modifier = _build_modifier_from_data(data["health_modifier"])
	var mana_modifier = _build_modifier_from_data(data["mana_modifier"])
	var attack_power_modifier = _build_modifier_from_data(data["attack_power_modifier"])
	var spell_power_modifier = _build_modifier_from_data(data["spell_power_modifier"])
	var movement_speed_modifier = _build_modifier_from_data(data["movement_speed_modifier"])
	
	var result = Status.new(is_debuff, duration, icon_texture_path)
	result.name = status_name
	result.tick_rate = tick_rate
	result.damage_per_tick = damage_per_tick
	result.healing_per_tick = healing_per_tick
	result.health_modifier = health_modifier
	result.mana_modifier = mana_modifier
	result.attack_power_modifier = attack_power_modifier
	result.spell_power_modifier = spell_power_modifier
	result.movement_speed_modifier = movement_speed_modifier
	
	return result


func _build_modifier_from_data(data) -> Modifier:
	var result = null
	
	if data && "value" in data && "modifier_type" in data:
		result = Modifier.new(data.value, data.modifier_type)
		
	return result
