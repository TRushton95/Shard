extends Node

var base_tick_healing := 1
var tick_healing_per_sp := 1

var tick_rate := 0.5

# Convention properties
var target_type = Enums.TargetType.Unit
var channel_duration := 5.0
var channel_cost := 5
# End of Convention properties


func _on_caster_channelling_ticked(target: Unit, caster: Unit) -> void:
	var healing = base_tick_healing + (tick_healing_per_sp * caster.spell_power_attr.value)
	target.heal(healing, name)


func _on_caster_channelling_stopped(caster: Unit) -> void:
	caster.disconnect("channelling_ticked", self, "_on_caster_channelling_ticked")
	caster.disconnect("channelling_stopped", self, "_on_caster_channelling_stopped")


func _ready():
	name = "Healing Stream"


func execute(target, caster) -> void:
	if !target is Unit:
		return
	
	caster.connect("channelling_ticked", self, "_on_caster_channelling_ticked", [target, caster])
	caster.connect("channelling_stopped", self, "_on_caster_channelling_stopped", [caster])
