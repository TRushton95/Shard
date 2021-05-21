extends KinematicBody2D
class_name Projectile

var target : Unit
var speed : int

signal target_reached


func _init() -> void:
	add_to_group(Constants.Groups.ABILITY_ENTITY)


func _process(delta: float) -> void:
	var distance = speed * delta
	var direction = position.direction_to(target.position)
	var velocity = direction * distance
	
	if position.distance_to(target.position) < distance:
		emit_signal("target_reached")
	else:
		position += velocity


func setup(target: Unit, position: Vector2, speed: int, radius: int, texture: Texture) -> void:
	self.target = target
	self.position = position
	self.speed = speed
	$CollisionShape2D.shape.radius = radius
	$Sprite.texture = texture


func setup_targetless(speed: int, radius: int, texture: Texture) -> void:
	self.speed = speed
	$CollisionShape2D.shape.radius = radius
	$Sprite.texture = texture
