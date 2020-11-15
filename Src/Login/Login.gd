extends Control

signal server_button_pressed
signal client_button_pressed


func _on_ServerButton_pressed():
	emit_signal("server_button_pressed")


func _on_ClientButton_pressed():
	emit_signal("client_button_pressed")
