extends Node

var map_scene = load("res://Gameplay/Maps/Map.tscn")
var lobby_scene = load("res://Lobby/Lobby.tscn")
var login_scene = load("res://Login/Login.tscn")

var player_lookup := {}
var player_name : String


func _on_connection_successful() -> void:
	$Login/VBoxContainer/Label.text = ""
	switch_to_lobby()


func _on_server_disconnected() -> void:
	switch_to_login()


func _on_Login_server_button_pressed() -> void:
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(1026, 2)
	get_tree().set_network_peer(peer)
	player_name = "Server"
	switch_to_lobby()


func _on_Login_client_button_pressed(ip, port) -> void:
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, int(port))
	get_tree().set_network_peer(peer)
	player_name = "Client"
	$Login/VBoxContainer/Label.text = "Connecting..."


func _on_connection_failed() -> void:
	$Login/VBoxContainer/Label.text = "Connection failed"


func _on_network_peer_connected(id) -> void:
	rpc_id(id, "register_player", player_name)


func _on_network_peer_disconnected(id) -> void:
	player_lookup.erase(id)
	get_node("Lobby").set_players(player_lookup)


func _on_Lobby_disconnect_button_pressed() -> void:
	switch_to_login()


func _on_Lobby_start_game_button_pressed() -> void:
	rpc("switch_to_game")


func _ready() -> void:
	get_tree().connect("connected_to_server", self, "_on_connection_successful")
	get_tree().connect("server_disconnected", self, "_on_server_disconnected")
	get_tree().connect("connection_failed", self, "_on_connection_failed")
	get_tree().connect("network_peer_connected", self, "_on_network_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_network_peer_disconnected")


remote func register_player(name) -> void:
	var sender_id = get_tree().get_rpc_sender_id()
	player_lookup[sender_id] = name
	get_node("Lobby").set_players(player_lookup)


remotesync func switch_to_game() -> void:
	get_node("Lobby").queue_free()
	var map = map_scene.instance()
	add_child(map)
	map.setup(player_name, player_lookup)


func switch_to_lobby() -> void:
	get_node("Login").queue_free()
	var lobby = lobby_scene.instance()
	lobby.player_name = player_name
	add_child(lobby)
	lobby.set_players(player_lookup)
	
	lobby.connect("disconnect_button_pressed", self, "_on_Lobby_disconnect_button_pressed")
	lobby.connect("start_game_button_pressed", self, "_on_Lobby_start_game_button_pressed")


func switch_to_login() -> void:
	get_node("Lobby").queue_free()
	var login = login_scene.instance()
	add_child(login)
	login.connect("server_button_pressed", self, "_on_Login_server_button_pressed")
	login.connect("client_button_pressed", self, "_on_Login_client_button_pressed")
	
	player_lookup.clear()
	get_tree().set_network_peer(null)
