extends Node

var target_type = Enums.TargetType.Unit
var damage := 5

func execute(target, caster) -> void:
	if !target is Unit:
		return
	
	target.rpc("damage", damage, name)
