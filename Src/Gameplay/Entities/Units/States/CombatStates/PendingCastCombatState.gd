extends State
class_name PendingCastCombatState

var _target
var _ability : Ability


func _init(target, ability) -> void:
	state_name = "PendingCastCombatState"
	_target = target
	_ability = ability


func update(unit, delta: float):
	if unit.is_in_range(_ability, _target):
		GameServer.send_ability_cast_request(_ability, unit.name)
		
		return CastingCombatState.new(_target, _ability)
	
	return null
