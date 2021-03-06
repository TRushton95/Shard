extends Control

const POSITION_OFFSET_RANGE := 50
const FLOAT_DISTANCE := 50
const DURATION := 0.75

var rng := RandomNumberGenerator.new()


func _on_Timer_timeout() -> void:
	queue_free()


func setup(number: int, position: Vector2, color: Color) -> void:
	self.modulate = color
	
	rng.randomize()
	var x = rng.randi_range(position.x - POSITION_OFFSET_RANGE / 2, position.x + POSITION_OFFSET_RANGE / 2)
	var y = rng.randi_range(position.y - POSITION_OFFSET_RANGE / 2, position.y)
	rect_position = Vector2(x, y)
	$Label.text = str(number)
	


func _ready() -> void:
	$Tween.interpolate_property($Label, "modulate:a", 1.0, 0.0, DURATION, Tween.TRANS_EXPO, Tween.EASE_IN)
	$Tween.interpolate_property($Label, "rect_position:y", 0, -FLOAT_DISTANCE, DURATION, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()
	$Timer.start(DURATION)
