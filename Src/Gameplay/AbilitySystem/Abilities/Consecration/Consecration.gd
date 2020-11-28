extends Ability

var consecration_texture = load("res://Gameplay/AbilitySystem/Abilities/Consecration/zone.png")

var tick_damage := 1
var tick_damage_per_sp := 0.5

var duration := 5.0
var tick_rate := 1.0
var radius := 100


func _on_zone_tick(affected_bodies: Array, caster: Unit) -> void:
	for body in affected_bodies:
		if get_tree().is_network_server():
			var damage = tick_damage + (tick_damage_per_sp * caster.spell_power_attr.value)
			body.rpc("damage", damage, name)


func _ready() -> void:
	target_type = Enums.TargetType.Position


func execute(target, caster: Unit) -> void:
	if !target is Vector2:
		return
		
	.try_start_cooldown()
	var zone = AbilityHelper.create_zone(target, duration, tick_rate, radius, consecration_texture)
	zone.connect("tick", self, "_on_zone_tick", [caster])
