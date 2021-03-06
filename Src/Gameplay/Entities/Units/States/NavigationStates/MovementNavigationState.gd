extends State
class_name MovementNavigationState

var _movement_path : PoolVector2Array
var _destination : Vector2
var _path_finished := false

signal state_path_set(path)
signal state_path_removed


func _init(destination: Vector2) -> void:
	state_name = "MovementNavigationState"
	_destination = destination


func on_enter(unit) -> void:
	.on_enter(unit)
	unit.is_moving = true
	_movement_path = NavigationHelper.get_simple_path(unit.position, _destination)
	
	emit_signal("state_path_set", _movement_path)


func on_leave(unit) -> void:
	unit.is_moving = false
	emit_signal("state_path_removed")
	.on_leave(unit)


func update(unit, delta: float):
	if unit.is_casting || unit.is_channelling:
		return
	
	var distance_to_walk = delta * unit.movement_speed_attr.value
	while distance_to_walk > 0 && _movement_path.size() > 0:
		distance_to_walk = _step_through_path(unit, distance_to_walk)
	
	if _movement_path.size() == 0:
		return IdleNavigationState.new()


func _step_through_path(unit, distance_to_walk: int) -> int:
	var distance_to_next_point = unit.position.distance_to(_movement_path[0])
	if distance_to_walk <= distance_to_next_point:
		unit.position += unit.position.direction_to(_movement_path[0]) * distance_to_walk
	else:
		unit.position = _movement_path[0]
		_movement_path.remove(0)
		
	distance_to_walk -= distance_to_next_point
	
	if _movement_path.size() > 0:
		unit.face_point(_movement_path[0])
	
	return distance_to_walk


func _connect_signals(unit) -> void:
	._connect_signals(unit)
	connect("state_path_set", unit, "_on_state_path_set")
	connect("state_path_removed", unit, "_on_state_path_removed")
	
	
func _disconnect_signals(unit) -> void:
	._disconnect_signals(unit)
	disconnect("state_path_set", unit, "_on_state_path_set")
	disconnect("state_path_removed", unit, "_on_state_path_removed")
