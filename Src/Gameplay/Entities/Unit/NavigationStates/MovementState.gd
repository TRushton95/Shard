extends Node
class_name MovementState

var state_name = "MovementState"

var _destination : Vector2
var _path_finished := false


func on_unit_path_finished() -> void:
	_path_finished = true


func _init(destination: Vector2) -> void:
	_destination = destination


func on_enter(unit) -> void:
	unit.set_movement_path(NavigationHelper.get_simple_path(unit.position, _destination))
	unit.connect("path_finished", self, "on_unit_path_finished")
	
	if !unit.is_casting && !unit.is_channelling:
		unit._play_animation(unit.AnimationType.WALKING, unit.direction)


func on_leave(unit) -> void:
	unit.set_movement_path([])


func update(unit, delta: float):
	if unit.casting_index > -1 || unit.channelling_index > -1:
		return
	
	var distance_to_walk = delta * unit.movement_speed_attr.value
	while distance_to_walk > 0 && unit._movement_path.size() > 0:
		distance_to_walk = unit._step_through_path(distance_to_walk) # FIXME: Don't like making unit move this way
	
	if _path_finished:
		return IdleNavigationState.new()
