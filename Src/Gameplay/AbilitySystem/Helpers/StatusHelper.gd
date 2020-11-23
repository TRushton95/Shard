extends Node


func dot(damage_per_tick: int, duration: float, tick_rate: float, icon_texture_path: String, status_name: String) -> Status:
	var result = Status.new(true, duration, icon_texture_path)
	result.icon_texture_path = icon_texture_path
	result.tick_damage = damage_per_tick
	result.tick_rate = tick_rate
	result.name = status_name
	
	return result


func build_from_data(data: Dictionary) -> Status:
	var status_name = data["name"]
	var icon_texture_path = data["icon_texture_path"]
	var is_debuff = data["is_debuff"]
	var duration = data["duration"]
	var tick_rate = data["tick_rate"]
	var tick_damage = data["tick_damage"]
	var tick_healing = data["tick_healing"]
	
	var result = Status.new(is_debuff, duration, icon_texture_path)
	result.name = status_name
	result.tick_rate = tick_rate
	result.tick_damage = tick_damage
	result.tick_healing = tick_healing
	
	return result
	
