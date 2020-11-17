extends ProgressBar

func set_current_value(new_value: int) -> void:
	value = new_value
	_refresh_label()


func set_max_value(new_max_value: int) -> void:
	max_value = new_max_value
	_refresh_label()


func initialise(new_max_value: int) -> void:
	max_value = new_max_value
	value = new_max_value
	_refresh_label()


func _refresh_label() -> void:
	$Label.text = str(value) + "/" + str(max_value)
