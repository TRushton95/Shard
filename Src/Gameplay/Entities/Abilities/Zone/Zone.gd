# Self contained instance of a zone that can provide predesigned on enter, on leave and tick effects
# For more complex zone behaviour, create a new scene with your ability that inherits from this scene, and
# and assign it a new script that extends Zone. In that script, override any of the necessary following hook methods:
#	_on_one_shot_details(affected_bodies: Array)
#	_on_tick_details(affected_bodies: Array)
#	_on_enter_details(body: Unit)
#	_on_leave_details(body: Unit)

extends Area2D
class_name Zone

var target
var one_shot := false
var stopwatch = Stopwatch.new()

var impact_damage := 0
var impact_healing := 0
var damage_per_tick := 0
var healing_per_tick := 0
var status : Status
var status_texture_path : String


func _on_Zone_body_entered(body) -> void:
	if !body is Unit:
		return
	
	if status:
		if get_tree().is_network_server():
			body.rpc("push_status_effect", status.to_data())
	
	_on_enter_details(body)


func _on_Zone_body_exited(body) -> void:
	if !body is Unit:
		return
		
	if status:
		if get_tree().is_network_server():
			body.rpc("remove_status_effect", status.name)
		
	_on_leave_details(body)


func _on_stopwatch_tick() -> void:
	if get_tree().is_network_server():
		for affected_body in get_overlapping_bodies():
			if damage_per_tick > 0:
				affected_body.rpc("damage", damage_per_tick, name)
			if healing_per_tick > 0:
				affected_body.rpc("heal", healing_per_tick, name)
				
	_on_tick_details(get_overlapping_bodies())


func _physics_process(_delta: float) -> void:
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
			
			if get_tree().is_network_server():
				if impact_damage > 0:
					collision_data.collider.rpc("damage", impact_damage, name)
				if impact_healing > 0:
					collision_data.collider.rpc("heal", impact_healing, name)
					
		_on_one_shot_details(affected_bodies)
		queue_free()


# Provide 0 duration for an instant transient zone
func setup(target, duration: float, tick_rate: int, radius: int, texture: Texture) -> void:
	self.target = target
	$CollisionShape2D.shape.radius = radius
	$Sprite.texture = texture
	
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


# Overridable hooks
func _on_one_shot_details(_affected_bodies: Array) -> void:
	pass


func _on_tick_details(_affected_bodies: Array) -> void:
	pass


func _on_enter_details(_body: Unit) -> void:
	pass


func _on_leave_details(_body: Unit) -> void:
	pass
# Overridable hooks
