extends PanelContainer


func set_name(name: String) -> void:
	$VBoxContainer/HBoxContainer/HBoxContainer/NameLabel.text = name


func set_range(ability_range: int) -> void:
	$VBoxContainer/HBoxContainer/HBoxContainer/RangeLabel.text = str(ability_range)


func set_cast_time(cast_time: float) -> void:
	var text = "Instant"
	if cast_time > 0:
		text = str(cast_time) + " sec"
		
	$VBoxContainer/CastTimeLabel.text = text


func set_cost(cost: int) -> void:
	$VBoxContainer/CostLabel.text = str(cost) + " mana"


func set_channel(channel_cost: int, tick_rate: float) -> void:
	if channel_cost > 0 && tick_rate > 0:
		$VBoxContainer/ChannelLabel.text = str(channel_cost) + " mana per " + str(tick_rate) + " sec"
		$VBoxContainer/ChannelLabel.show()
	else:
		$VBoxContainer/ChannelLabel.hide()


func set_description(description: String) -> void:
	$VBoxContainer/DescriptionLabel.text = description
