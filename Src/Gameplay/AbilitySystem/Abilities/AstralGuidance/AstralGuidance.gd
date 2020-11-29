extends Ability

var zone_scene = load("res://Gameplay/Entities/Abilities/Zone/Zone.tscn")
var consecration_texture = load("res://Gameplay/AbilitySystem/Abilities/Consecration/zone.png")
var status_texture = load("res://Gameplay/AbilitySystem/Abilities/AstralGuidance/astral_guidance_status_icon.png")

var duration := Constants.INDEFINITE_DURATION
var radius := 100

var active := false
var zone : Zone

func _ready() -> void:
	target_type = Enums.TargetType.Self
	toggled = true


func deactivate() -> void:
	zone.queue_free()
	active = false


func execute(target, caster: Unit) -> void:
	if !target is Unit:
		return
		
	.try_start_cooldown()
	
	zone = zone_scene.instance()
	zone.target = target
	zone.duration = duration
	zone.tick_rate = 0.0
	zone.radius = radius
	zone.texture = consecration_texture
	zone.position = target.position
	get_tree().get_root().add_child(zone) # TODO: This shouldn't be added to the tree root
	zone.setup()
	
	var status = Status.new()
	status.name = "Astral Guidance"
	status.is_debuff = false
	status.duration = Constants.INDEFINITE_DURATION
	status.mana_modifier = Modifier.new(20, Enums.ModifierType.Additive)
	status.icon_texture = status_texture
	
	zone.status = status
	active = true
