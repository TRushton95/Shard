extends TextureButton


func _on_CloseButton_mouse_entered():
	lighten()


func _on_CloseButton_mouse_exited():
	darken()


func _on_CloseButton_hide():
	darken()


func lighten() -> void:
	material.set_shader_param("brightness_modifier", 0.25)


func darken() -> void:
	material.set_shader_param("brightness_modifier", 0)
