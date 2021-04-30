extends Node

var time : int
var latency: int


func synchronise() -> void:
	if is_network_master():
		rpc_id(1, "_get_server_time", OS.get_system_time_msecs())
	else:
		print("Server may not sync it's own clock.")


remote func _get_server_time(client_time: int) -> void:
	var player_id = get_tree().get_rpc_sender_id()
	rpc_id(player_id, "_return_server_time", OS.get_system_time_msecs(), client_time)


remote func _return_server_time(server_time: int, client_time: int) -> void:
	latency = (OS.get_system_time_msecs() - client_time) / 2
	time = server_time + latency
