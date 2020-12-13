extends Node

var _nav_instance

func set_nav_instance(nav_instance: NavigationPolygonInstance) -> void:
	_nav_instance = nav_instance


func get_simple_path(from: Vector2, to: Vector2) -> PoolVector2Array:
	if !_nav_instance:
		print("Navigation instance not set")
		return PoolVector2Array()
	
	return _nav_instance.get_simple_path(from, to)
