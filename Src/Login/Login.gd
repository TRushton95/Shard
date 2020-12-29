extends Control

signal server_button_pressed
signal client_button_pressed(ip, port)


func _on_ServerButton_pressed() -> void:
	emit_signal("server_button_pressed")


func _on_ClientButton_pressed() -> void:
	var ip = $VBoxContainer/NetworkPanel/VBoxContainer/HBoxContainer/IpField.text
	var port = $VBoxContainer/NetworkPanel/VBoxContainer/HBoxContainer/PortField.text
	emit_signal("client_button_pressed", ip, port)
