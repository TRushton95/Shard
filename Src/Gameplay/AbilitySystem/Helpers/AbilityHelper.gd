extends Node

var projectile_scene = load("res://Gameplay/Entities/Abilities/Projectile/Projectile.tscn")


func create_projectile(target: Unit, position: Vector2, speed: int, radius: int, texture: Texture) -> Projectile:
	var projectile = projectile_scene.instance()
	get_tree().get_root().add_child(projectile)
	projectile.setup(target, position, speed, radius, texture)
	
	return projectile
