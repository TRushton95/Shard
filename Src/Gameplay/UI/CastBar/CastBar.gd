extends ProgressBar


func initialise(text: String, max_value: int) -> void:
	$Label.text = text
	self.max_value = max_value
	self.value = 0


func set_value(new_value: float) -> void:
	value = new_value
