extends GridContainer

var status_effect_widget_scene = load("res://Gameplay/UI/StatusEffectBar/StatusEffectWidget.tscn")


func add_status_effect(status_effect: Status) -> void:
	var status_effect_widget = status_effect_widget_scene.instance()
	
	var icon_texture = load(status_effect.icon_texture_path)
	status_effect_widget.setup(icon_texture, status_effect.duration)
	add_child(status_effect_widget)


func remove_status_effect(index: int) -> void:
	get_child(index).queue_free()


func update_duration(index: int, duration: float) -> void:
	get_child(index).set_duration(duration)


func clear() -> void:
	for item in get_children():
		item.queue_free()
