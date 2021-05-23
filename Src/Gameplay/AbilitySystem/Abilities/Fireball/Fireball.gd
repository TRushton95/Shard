extends Ability

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


func _on_projectile_target_reached(projectile: Projectile, target: Unit, caster: Unit) -> void:
	projectile.queue_free()
	
	if get_tree().is_network_server():
		var damage = base_damage + (damage_per_sp * caster.spell_power_attr.value)
		target.rpc("damage", damage, get_instance_id(), _owner_id)
		
		var dot_damage = base_dot_damage + (dot_damage_per_sp * caster.spell_power_attr.value)
		var dot = StatusHelper.dot(dot_name, dot_damage, dot_duration, dot_tick_rate, burn_icon_texture, get_instance_id(), _owner_id)
		
		target.rpc("push_status_effect", dot.to_data())


func _ready() -> void:
	target_type = Enums.TargetType.Unit
	target_team = Enums.Team.Enemy
	cast_range = 500


func execute(target, caster: Unit) -> void:
	if !target is Unit:
		return
	
	_owner_id = caster.get_instance_id()
	var projectile = AbilityHelper.get_ability_entity(Enums.AbilityEntity.FIREBALL)
	projectile.target = target
	
	var offset = Vector2(0, caster.get_size().y / 2)
	projectile.position = caster.position - offset
	get_tree().get_root().add_child(projectile)
	
	var ability_entity_state = {
		Constants.Network.ID: 99999,
		Constants.Network.TIME: ServerClock.get_time(),
		Constants.Network.ABILITY_ENTITY_TYPE: Enums.AbilityEntity.FIREBALL,
		Constants.Network.POSITION: projectile.position,
		Constants.Network.OWNER_ID: caster.name,
		Constants.Network.TARGET_ID: target.name
	}
	
	get_tree().get_root().get_node("Main/Map")._send_ability_entity_state(ability_entity_state)
	
	projectile.connect("target_reached", self, "_on_projectile_target_reached", [projectile, target, caster])
