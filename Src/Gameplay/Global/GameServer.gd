extends Node

var game_map

func initialise() -> void:
	game_map = get_tree().get_root().get_node("Main/Map") # Initialising this on load results in attempting to reference map before it is instantiated


###################
#  CLIENT METHODS #
###################

# TODO: Think this is safe to be removed now, replaced by send_ability_cast_request
func send_ability_cast(ability_source: int, ability_index: int, target) -> void:
	game_map.rpc_id(Constants.SERVER_ID, "receive_ability_cast", ability_source, ability_index, target)


func send_player_state(player_state: Dictionary) -> void:
	game_map.rpc_unreliable_id(Constants.SERVER_ID, "receive_player_state", player_state)


# TODO: Consider refactoring abilities to all have an ID and be lookupable in a universal way
func send_ability_cast_request(ability: Ability, target) -> void:
	var ability_instance_id = ability.get_instance_id()
	game_map.rpc_id(Constants.SERVER_ID, "receive_ability_cast_request", ServerClock.get_time(), ability_instance_id, target)


###################
#  SERVER METHODS #
###################

func broadcast_ability_entity_state(ability_entity_state) -> void:
	game_map.rpc_id(Constants.ALL_CONNECTED_PEERS_ID, "receive_ability_entity_state", ability_entity_state)


func broadcast_world_state(world_state: Dictionary) -> void:
	game_map.rpc_unreliable_id(Constants.ALL_CONNECTED_PEERS_ID, "receive_world_state", world_state)
