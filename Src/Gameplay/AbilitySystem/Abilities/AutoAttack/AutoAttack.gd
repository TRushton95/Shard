# Empty ability to force an attack

extends Ability


func _ready() -> void:
	target_type = Enums.TargetType.Unit
	target_team = Enums.Team.Enemy
	cast_range = 0


remotesync func execute(target, caster: Unit) -> void:
	if target != Unit:
		return
