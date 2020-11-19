extends TextureProgress

func set_current_value(new_value: int) -> void:
	value = new_value


func set_max_value(new_max_value: int) -> void:
	max_value = new_max_value


func initialise(new_max_value: int) -> void:
	max_value = new_max_value
	value = new_max_value
