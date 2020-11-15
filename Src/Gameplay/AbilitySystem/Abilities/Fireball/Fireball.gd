extends Node

var fireball_texture = load("res://Gameplay/AbilitySystem/Abilities/Fireball/fireball.png")

var target_type = Enums.TargetType.Unit
var damage := 10
var dot_damage_per_tick := 1
var dot_duration := 5.0
var dot_tick_rate = 1.0
var dot_name = "Burn"
var _projectile_speed := 500
var cast_time := 1.0


func _on_projectile_target_reached(projectile: Projectile, target: Unit):
	projectile.queue_free()
	
	if get_tree().is_network_server():
		target.rpc("damage", damage, name)
		
		var dot = StatusHelper.dot(dot_damage_per_tick, dot_duration, dot_tick_rate, dot_name)
		var test = dot.to_data()
		
		target.rpc("push_status_effect", dot.to_data())
		


remotesync func execute(target, caster: Unit) -> void:
	if !target is Unit:
		return
	
	var radius = fireball_texture.get_width() / 2
	var projectile = AbilityHelper.create_projectile(target, caster.position, _projectile_speed, radius, fireball_texture)
	projectile.connect("target_reached", self, "_on_projectile_target_reached", [projectile, target])
