extends Node

var fireball_texture = load("res://Gameplay/AbilitySystem/Abilities/Fireball/fireball.png")
var burn_icon_texture = load("res://Gameplay/AbilitySystem/Abilities/Fireball/burn_icon.png")

var base_damage := 10
var damage_per_sp := 1.0
var base_dot_damage := 1
var dot_damage_per_sp := 0.5

var dot_duration := 5.0
var dot_tick_rate = 1.0
var dot_name = "Burn"
var _projectile_speed := 500

# Convention properties
var target_type = Enums.TargetType.Unit
var cost := 5
var cast_time := 1.0
var icon = load("res://Gameplay/AbilitySystem/Abilities/Fireball/icon.png") # move this into an ability base class that references icon.png with a relative path
# End of Convention properties


func _on_projectile_target_reached(projectile: Projectile, target: Unit, caster: Unit):
	projectile.queue_free()
	
	if get_tree().is_network_server():
		var damage = base_damage + (damage_per_sp * caster.spell_power_attr.value)
		target.rpc("damage", damage, name)
		
		var dot_damage = base_dot_damage + (dot_damage_per_sp * caster.spell_power_attr.value)
		var dot = StatusHelper.dot(dot_damage, dot_duration, dot_tick_rate, burn_icon_texture.resource_path, dot_name)
		
		target.rpc("push_status_effect", dot.to_data())
		


remotesync func execute(target, caster: Unit) -> void:
	if !target is Unit:
		return
	
	var radius = fireball_texture.get_width() / 2
	var projectile = AbilityHelper.create_projectile(target, caster.position, _projectile_speed, radius, fireball_texture)
	projectile.connect("target_reached", self, "_on_projectile_target_reached", [projectile, target, caster])
