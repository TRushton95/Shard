extends Node

var _players = {}


func add_user(id: int, user_name: String) -> void:
	if _players.has(id):
		print("Player id " + str(id) + " is already assigned.")
		return
	
	_players[id] = user_name


func remove_user(id: int) -> void:
	if _players.has(id):
		_players.erase(id)


func get_user_name(id: int) -> String:
	var result = ""
	
	if _players.has(id):
		result = _players[id]
	
	return result


func get_players() -> Dictionary:
	return _players


func get_sorted_user_ids() -> Array:
	var result = []
	
	for user_id in _players.keys():
		result.push_back(user_id)
		
	result.sort()
	
	return result


func clear() -> void:
	_players = {}
