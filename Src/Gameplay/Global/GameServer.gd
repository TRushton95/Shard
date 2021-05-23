extends Node


# TODO: Consider refactoring abilities to all have an ID and be lookupable in a universal way
func send_ability_cast(ability_source: int, ability_index: int, target) -> void:
	get_tree().get_root().get_node("Main/Map").rpc_id(Constants.SERVER_ID, "recieve_ability_cast", ability_source, ability_index, target)


func request_ability_cast(ability: Ability, target) -> void:
	var ability_instance_id = ability.get_instance_id()
	get_tree().get_root().get_node("Main/Map").rpc_id(Constants.SERVER_ID, "recieve_ability_cast_request", ServerClock.get_time(), ability_instance_id, target)
