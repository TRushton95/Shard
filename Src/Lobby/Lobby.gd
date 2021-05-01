extends Control

signal start_game_button_pressed
signal disconnect_button_pressed

var player_name: String


func _on_StartGameButton_pressed():
	emit_signal("start_game_button_pressed")


func _on_DisconnectButton_pressed():
	emit_signal("disconnect_button_pressed")


func _ready() -> void:
	if get_tree().is_network_server():
		$Panel/VBoxContainer/StartGameButton.visible = true


func set_players() -> void: # TODO: Tidy up this player_lookup, player_list shit, it's a mess and it's totally pointless
	var player_list = $Panel/MarginContainer/VBoxContainer/PlayerList
	player_list.clear()
		
	for user_id in ServerInfo.get_sorted_user_ids():
		var user_name = ServerInfo.get_user_name(user_id)
		if user_id == get_tree().get_network_unique_id():
			user_name += " (you)"
			
		player_list.add_item(user_name)
	
	$Panel/MarginContainer/VBoxContainer/PlayerCountLabel.text = str(ServerInfo.get_players().size()) + "/2"
