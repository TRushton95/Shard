extends Node


func get_target_position(target) -> Vector2:
	return target if target is Vector2 else target.position
