extends Control

signal start_game_button_pressed
signal disconnect_button_pressed

var player_name: String


func _on_StartGameButton_pressed():
	pass # Replace with function body.


func _on_DisconnectButton_pressed():
	emit_signal("disconnect_button_pressed")


func set_players(players: Dictionary) -> void:
	var player_list = $Panel/MarginContainer/VBoxContainer/PlayerList
	player_list.clear()
	player_list.add_item(player_name + " (you)")

	for player in players.values():
		player_list.add_item(player)
	
	$Panel/MarginContainer/VBoxContainer/PlayerCountLabel.text = str(players.size() + 1) + "/2"
