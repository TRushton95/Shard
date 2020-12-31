extends Node

var aggressive := false
var timer = Timer.new()
var STATE_RESET_TIME = 2

func _ready() -> void:
	add_child(timer)
	timer.one_shot = true
	timer.start(STATE_RESET_TIME)


# No type: cyclical reference
func update(unit) -> void:
	if timer.is_stopped():
		aggressive = !aggressive
		
		if aggressive:
			unit.input_command(AttackCommand.new(unit.target))
		else:
			unit.input_command(StopCommand.new())
			
		timer.start(STATE_RESET_TIME)
