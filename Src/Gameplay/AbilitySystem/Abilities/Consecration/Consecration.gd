extends Node

var tick_damage := 1
var duration := 5.0
var tick_rate := 1.0
var radius := 50
var cast_time := 1.0

var target_type = Enums.TargetType.Position


func _on_zone_tick(affected_bodies: Array) -> void:
	for body in affected_bodies:
		if get_tree().is_network_server():
			body.rpc("damage", tick_damage, name)


func execute(target, caster: Unit) -> void:
	if !target is Vector2:
		return
		
	var zone = AbilityHelper.CreateZone(target, duration, tick_rate, radius)
	zone.connect("tick", self, "_on_zone_tick")
