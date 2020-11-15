extends KinematicBody2D
class_name Unit

var _path : PoolVector2Array
var speed := 250
var max_health := 100
var current_health := max_health
var is_casting := false

signal left_clicked
signal path_finished
signal casting_started
signal casting_stopped
signal casting_progress
signal damage_received(value)
signal healing_received(unit, value)


func _on_Clickbox_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton && event.pressed:
		if event.button_index == BUTTON_LEFT:
			emit_signal("left_clicked")


func _on_CastTimer_timeout(ability, unit) -> void:
	stop_casting()
	ability.execute(unit, self)


func _ready():
	$CastTimer.one_shot = false


func _process(delta: float) -> void:
	if _path && _path.size() > 0:
		_move_along_path(delta)
		
	if is_casting:
		emit_signal("casting_progress", $CastTimer.wait_time - $CastTimer.time_left)


remotesync func set_path(path: PoolVector2Array) -> void:
	_path = path


remotesync func damage(value: int, source_name: String) -> void:
	current_health -= value
	
	if current_health < 0:
		current_health = 0
	
	print("%s received %s damage from %s" % [name, value, source_name])
	emit_signal("damage_received", value)


remotesync func heal(value: int, source_name: String) -> void:
	current_health += value
	
	if current_health > max_health:
		current_health = max_health
	
	print("%s received %s healing from %s" % [name, value, source_name])
	emit_signal("healing_received", value)


func cast(index: int, target) -> void:
	if is_casting:
		print("Already casting")
		return
		
	var ability = $Abilities.get_child(index)
	
	if "cast_time" in ability && ability.cast_time > 0:
		$CastTimer.connect("timeout", self, "_on_CastTimer_timeout", [ability, target])
		$CastTimer.start(ability.cast_time)
		is_casting = true
		emit_signal("casting_started", ability.name, ability.cast_time)
	else:
		ability.execute(target, self)


func stop_casting() -> void:
	print("Stopping cast")
	is_casting = false
	$CastTimer.stop()
	$CastTimer.disconnect("timeout", self, "_on_CastTimer_timeout")
	emit_signal("casting_stopped")


func _move_along_path(delta: float) -> void:
	var distance_to_walk = delta * speed
	
	while distance_to_walk > 0 && _path.size() > 0:
		var distance_to_next_point = position.distance_to(_path[0])
		if distance_to_walk <= distance_to_next_point:
			position += position.direction_to(_path[0]) * distance_to_walk
		else:
			position = _path[0]
			_path.remove(0)
			
		distance_to_walk -= distance_to_next_point
		
		if _path.size() == 0:
			emit_signal("path_finished")
