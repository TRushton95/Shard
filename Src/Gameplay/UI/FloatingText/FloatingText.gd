extends Label

const POSITION_OFFSET_RANGE = 50

var rng = RandomNumberGenerator.new()


func _on_Timer_timeout() -> void:
	queue_free()


func setup(number: int, position: Vector2) -> void:
	rng.randomize()
	var x = rng.randi_range(position.x - POSITION_OFFSET_RANGE / 2, position.x + POSITION_OFFSET_RANGE / 2)
	var y = rng.randi_range(position.y - POSITION_OFFSET_RANGE / 2, position.y + POSITION_OFFSET_RANGE / 2)
	rect_position = Vector2(x, y)
	text = str(number)


func _ready() -> void:
	$Timer.start(1) # Replace timer with fade out animation
