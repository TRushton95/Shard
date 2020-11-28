extends Ability

var consecration_texture = load("res://Gameplay/AbilitySystem/Abilities/Consecration/zone.png")
var hallowed_ground_texture = load("res://Gameplay/AbilitySystem/Abilities/Consecration/hallowed_ground.png")

var tick_damage := 1
var tick_damage_per_sp := 0.5

var duration := 15.0
var tick_rate := 1.0
var radius := 100

var is_status_debuff = true


func _ready() -> void:
	target_type = Enums.TargetType.Position


func execute(target, caster: Unit) -> void:
	if !target is Vector2:
		return
		
	.try_start_cooldown()
	var zone = AbilityHelper.create_zone(target, duration, tick_rate, radius, consecration_texture)
	zone.damage_per_tick = tick_damage + (tick_damage_per_sp * caster.spell_power_attr.value)
	
	var status = Status.new(is_status_debuff, -1, hallowed_ground_texture.resource_path)
	status.name = "Hallowed Ground"
	status.movement_speed_modifier = Modifier.new(0.5, Enums.ModifierType.Multiplicative)
	zone.status = status
