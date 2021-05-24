extends Node


func get_target_position(target) -> Vector2:
	return target if target is Vector2 else target.position


# Get target from dirty target that may be a Vector2 or a node name
func get_clean_target(dirty_target):
	var result
	
	if dirty_target is Vector2:
		result = dirty_target
	elif has_node(dirty_target):
		result = get_node(dirty_target)
		
	return result
