# Self contained instance of a zone that can provide predesigned on enter, on leave and tick effects
# For more complex zone behaviour, create a new scene with your ability that inherits from this scene, and
# and assign it a new script that extends Zone. In that script, override any of the necessary following hook methods:
#	_on_one_shot_details(affected_bodies: Array)
#	_on_tick_details(affected_bodies: Array)
#	_on_enter_details(body: Unit)
#	_on_leave_details(body: Unit)

extends Area2D
class_name Zone

var _owner_id := -1
var target
var one_shot := false
var stopwatch = Stopwatch.new()

var duration := 0.0 # 0.0 duration for an instant transient zone, -1.0 for permenant zone - see Constants.gd
var tick_rate := 0.0
var radius := 0  setget _set_radius
var team := -1
var friendly_impact_damage := 0
var friendly_impact_healing := 0
var hostile_impact_damage := 0
var hostile_impact_healing := 0
var friendly_damage_per_tick := 0
var friendly_healing_per_tick := 0
var hostile_damage_per_tick := 0
var hostile_healing_per_tick := 0
var texture : Texture setget _set_texture
var hostile_status : Status
var friendly_status : Status


func _init() -> void:
	add_to_group(Constants.Groups.ABILITY_ENTITY)


func _on_Zone_body_entered(body) -> void:
	if !body is Unit:
		return
	
	if get_tree().is_network_server():
		if body.team == team && friendly_status:
			body.rpc("push_status_effect", friendly_status.to_data())
		elif body.team != team && hostile_status:
			body.rpc("push_status_effect", hostile_status.to_data())
	
	_on_enter_details(body)


func _on_Zone_body_exited(body) -> void:
	if !body is Unit:
		return
		
	if get_tree().is_network_server():
		if body.team == team && friendly_status:
			body.rpc("remove_status_effect", friendly_status.name)
		elif body.team != team && hostile_status:
			body.rpc("remove_status_effect", hostile_status.name)
		
	_on_leave_details(body)


func _on_stopwatch_tick() -> void:
	if get_tree().is_network_server():
		for affected_body in get_overlapping_bodies():
			if affected_body.team == team:
				if friendly_damage_per_tick > 0:
					affected_body.rpc("damage", friendly_damage_per_tick, get_instance_id(), _owner_id)
				if friendly_healing_per_tick > 0:
					affected_body.rpc("heal", friendly_healing_per_tick, get_instance_id(), _owner_id)
			else:
				if hostile_damage_per_tick > 0:
					affected_body.rpc("damage", hostile_damage_per_tick, get_instance_id(), _owner_id)
				if hostile_healing_per_tick > 0:
					affected_body.rpc("heal", hostile_healing_per_tick, get_instance_id(), _owner_id)
				
	_on_tick_details(get_overlapping_bodies())


func _on_stopwatch_timeout() -> void:
	if duration == Constants.INDEFINITE_DURATION:
		stopwatch.start()
	else:
		queue_free()


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
			var affected_body = collision_data.collider
			affected_bodies.push_back(affected_body)
			
			if get_tree().is_network_server():
				if affected_body.team == team:
					if friendly_impact_damage > 0:
						collision_data.collider.rpc("damage", friendly_impact_damage, get_instance_id(), _owner_id)
					if friendly_impact_healing > 0:
						collision_data.collider.rpc("heal", friendly_impact_healing, get_instance_id(), _owner_id)
				else:
					if hostile_impact_damage > 0:
						collision_data.collider.rpc("damage", hostile_impact_damage, get_instance_id(), _owner_id)
					if hostile_impact_healing > 0:
						collision_data.collider.rpc("heal", hostile_impact_healing, get_instance_id(), _owner_id)
					
		_on_one_shot_details(affected_bodies)
		queue_free()


func setup(owner_id: int) -> void:
	_owner_id = owner_id
	
	if target is Vector2:
		position = target # Set vector2 position here to avoid resetting every _physics_process
	
	if duration != Constants.ONE_SHOT_DURATION:
		var adjusted_duration = tick_rate if duration == Constants.INDEFINITE_DURATION else duration
		stopwatch.setup(adjusted_duration, tick_rate)
		add_child(stopwatch)
		stopwatch.connect("timeout", self, "_on_stopwatch_timeout")
		stopwatch.connect("tick", self, "_on_stopwatch_tick")
		stopwatch.start()
		
	else:
		# List of overlapping bodies is updated each physics frame
		# so the colliders are not available here. Instead, physics space must
		# be used for immediate calculation, but that must be accessed in _physics_process
		# only, so a one_shot zone should be flagged and handled there.
		one_shot = true


func _set_radius(value: int) -> void:
	radius = value
	$CollisionShape2D.shape.radius = value


func _set_texture(value: Texture) -> void:
	texture = value
	$Sprite.texture = texture


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
