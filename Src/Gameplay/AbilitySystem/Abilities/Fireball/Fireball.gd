extends Node

var fireball_texture = load("res://Gameplay/AbilitySystem/Abilities/Fireball/fireball.png")

var target_type = Enums.TargetType.Unit
var damage := 5
var _speed := 500
var cast_time := 1.0


func _on_projectile_target_reached(projectile: Projectile, target):
	projectile.queue_free()
	
	if get_tree().is_network_server():
		target.rpc("damage", damage, name)


remotesync func execute(target, caster) -> void:
	if !target is Unit:
		return
	
	var radius = fireball_texture.get_width() / 2
	var projectile = AbilityHelper.create_projectile(target, caster.position, _speed, radius, fireball_texture)
	projectile.connect("target_reached", self, "_on_projectile_target_reached", [projectile, target])
