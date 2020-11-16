extends Area2D
class_name Zone

var target
var one_shot := false
var stopwatch = Stopwatch.new()

signal tick(affected_bodies)
signal one_shot(affected_bodies)


func _on_stopwatch_tick() -> void:
	var affected_bodies = get_overlapping_bodies()
	emit_signal("tick", affected_bodies)


func _physics_process(delta: float) -> void:
	if target is Unit:
		position = target.position
	
	if one_shot:
		var query_params = Physics2DShapeQueryParameters.new()
		query_params.set_shape($CollisionShape2D.shape)
		query_params.transform.origin = position
		
		var query_result = get_world_2d().direct_space_state.intersect_shape(query_params)
		
		var affected_bodies = []
		for collision_data in query_result:
			affected_bodies.push_back(collision_data.collider)
			
		emit_signal("one_shot", affected_bodies)
		queue_free()


# Provide 0 duration for an instant transient zone
func setup(target, duration: float, tick_rate: int, radius: int) -> void:
	self.target = target
	$CollisionShape2D.shape.radius = radius
	
	if target is Vector2:
		position = target # Set vector2 position here to avoid resetting every _physics_process
	
	if duration > 0:
		stopwatch.setup(duration, tick_rate)
		add_child(stopwatch)
		stopwatch.connect("timeout", self, "queue_free")
		stopwatch.connect("tick", self, "_on_stopwatch_tick")
		stopwatch.start()
		
	else:
		# List of overlapping bodies is updated each physics frame
		# so the colliders are not available here. Instead, physics space must
		# be used for immediate calculation, but that must be accessed in _physics_process
		# only, so a one_shot zone should be flagged and handled there.
		one_shot = true
