extends Node

var channel_duration := 5.0
var healing_per_tick := 1
var tick_rate := 0.5

var target_type = Enums.TargetType.Unit


func _on_caster_channelling_ticked(target: Unit) -> void:
	target.heal(healing_per_tick, name)


func _on_caster_channelling_stopped(caster: Unit) -> void:
	caster.disconnect("channelling_ticked", self, "_on_caster_channelling_ticked")
	caster.disconnect("channelling_stopped", self, "_on_caster_channelling_stopped")


func _ready():
	name = "Healing Stream"


func execute(target, caster) -> void:
	if !target is Unit:
		return
	
	caster.connect("channelling_ticked", self, "_on_caster_channelling_ticked", [target])
	caster.connect("channelling_stopped", self, "_on_caster_channelling_stopped", [caster])
