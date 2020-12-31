extends State
class_name AttackingCombatState

var _target


func _init(target) -> void:
	state_name = "AttackingCombatState"
	_target = target


func on_enter(unit) -> void:
	.on_enter(unit)
	unit.is_basic_attacking = true


func on_leave(unit) -> void:
	unit.is_basic_attacking = false
	.on_leave(unit)


func update(unit, delta: float) -> void:
	if unit.is_basic_attack_off_cooldown() && unit.position.distance_to(_target.position) <= unit.basic_attack_range:
		unit.basic_attack(_target)
