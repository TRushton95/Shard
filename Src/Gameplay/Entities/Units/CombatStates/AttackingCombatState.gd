extends Node
class_name AttackingCombatState

var state_name = "AttackingCombatState"

var _target


func _init(target) -> void:
	_target = target


func on_enter(unit) -> void:
	unit.is_basic_attacking = true


func on_leave(unit) -> void:
	unit.is_basic_attacking = false


func update(unit, delta: float) -> void:
	if unit.is_basic_attack_off_cooldown() && unit.position.distance_to(_target.position) <= unit.basic_attack_range:
		unit.basic_attack(_target)
