extends Ability

var base_tick_healing := 1
var tick_healing_per_sp := 1

# Convention properties
var channel_time := 5.0
var channel_cost := 1
var tick_rate := 0.5
# End of Convention properties


func _on_caster_channelling_ticked(target: Unit, caster: Unit) -> void:
	var healing = base_tick_healing + (tick_healing_per_sp * caster.spell_power_attr.value)
	target.heal(healing, name)


func _on_caster_channelling_stopped(ability_name: String, caster: Unit) -> void:
	caster.disconnect("channelling_ticked", self, "_on_caster_channelling_ticked")
	caster.disconnect("channelling_stopped", self, "_on_caster_channelling_stopped")


func _ready():
	name = "Healing Stream"
	target_type = Enums.TargetType.Unit
	target_team = Enums.Team.Ally


func execute(target, caster) -> void:
	if !target is Unit:
		return
	
	caster.connect("channelling_ticked", self, "_on_caster_channelling_ticked", [target, caster])
	caster.connect("channelling_stopped", self, "_on_caster_channelling_stopped", [caster])
