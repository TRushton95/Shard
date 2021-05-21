extends Node

var projectile_scene := load("res://Gameplay/Entities/Abilities/Projectile/Projectile.tscn")

var _projectile_speed := 500

func create_projectile(target: Unit, position: Vector2, speed: int, radius: int, texture: Texture) -> Projectile:
	var projectile = projectile_scene.instance()
	get_tree().get_root().add_child(projectile)
	projectile.setup(target, position, speed, radius, texture)
	
	return projectile


func _create_projectile_entity(speed: int, texture: Texture) -> Projectile:
	var projectile = projectile_scene.instance()
	
	var hitbox_radius = texture.get_width()
	projectile.setup_targetless(speed, hitbox_radius, texture)
	
	return projectile


func get_ability_entity(entity_type):
	match entity_type:
		Enums.AbilityEntity.FIREBALL:
			var fireball_texture = load("res://Gameplay/AbilitySystem/Abilities/Fireball/fireball.png")
			return _create_projectile_entity(_projectile_speed, fireball_texture)
