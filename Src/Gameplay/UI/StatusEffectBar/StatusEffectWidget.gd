extends VBoxContainer

func setup(icon_texture: Texture, duration: float = 0.0) -> void:
	$Icon.texture = icon_texture
	
	if duration > 0.0:
		set_duration(duration)
		$DurationLabel.show()


func set_duration(duration: float) -> void:
	$DurationLabel.text = "%ss" % [ceil(duration)]
