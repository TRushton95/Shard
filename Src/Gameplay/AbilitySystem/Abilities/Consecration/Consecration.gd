extends Ability

var zone_scene = load("res://Gameplay/Entities/Abilities/Zone/Zone.tscn")
var consecration_texture = load("res://Gameplay/AbilitySystem/Abilities/Consecration/zone.png")
var hallowed_ground_texture = load("res://Gameplay/AbilitySystem/Abilities/Consecration/hallowed_ground.png")

var tick_damage := 1
var tick_damage_per_sp := 0.5

var duration := 5.0
var tick_rate := 1.0
var radius := 100

var status_name = "Hallowed Ground"
var status_speed_multiplier = 0.5
var status_duration = Constants.INDEFINITE_DURATION
var is_debuff = true


func _ready() -> void:
	target_type = Enums.TargetType.Position
	cast_range = 250


func execute(target, caster: Unit) -> void:
	if !target is Vector2:
		return
		
	.try_start_cooldown()
	
	var zone = zone_scene.instance()
	zone.target = target
	zone.duration = duration
	zone.tick_rate = tick_rate
	zone.radius = radius
	zone.damage_per_tick = tick_damage + (tick_damage_per_sp * caster.spell_power_attr.value)
	zone.texture = consecration_texture
	get_tree().get_root().add_child(zone) # TODO: This shouldn't be added to the tree root
	zone.setup()
	
	var status = Status.new()
	status.is_debuff = is_debuff
	status.duration = status_duration
	status.name = status_name
	status.movement_speed_modifier = Modifier.new(status_speed_multiplier, Enums.ModifierType.Multiplicative)
	status.icon_texture = hallowed_ground_texture
	
	zone.status = status
