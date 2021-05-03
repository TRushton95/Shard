extends Node


func send_ability_cast(ability_source: int, ability_index: int, target) -> void:
	get_tree().get_root().get_node("Main/Map").rpc_id(Constants.SERVER_ID, "receive_ability_cast", ability_source, ability_index, target)
