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


func set_players(player_lookup: Dictionary) -> void:
	var player_list = $Panel/MarginContainer/VBoxContainer/PlayerList
	player_list.clear()
	player_list.add_item(player_name + " (you)")

	for player in player_lookup.values():
		player_list.add_item(player)
	
	$Panel/MarginContainer/VBoxContainer/PlayerCountLabel.text = str(player_lookup.size() + 1) + "/2"
