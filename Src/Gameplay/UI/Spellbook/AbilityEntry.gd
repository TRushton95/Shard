extends HBoxContainer


func setup(label: String, action_button: ActionButton) -> void:
	$Label.text = label
	$ButtonSlot.add_button(action_button)


func get_button() -> ActionButton:
	return $ButtonSlot.get_button()
