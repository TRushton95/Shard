extends VBoxContainer

func setup(icon_texture: Texture, duration: float) -> void:
	$Icon.texture = icon_texture
	set_duration(duration)


func set_duration(duration: float) -> void:
	$Label.text = "%ss" % [ceil(duration)]
