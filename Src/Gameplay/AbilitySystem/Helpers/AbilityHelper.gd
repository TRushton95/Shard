extends Node

var projectile_scene = load("res://Gameplay/Entities/Abilities/Projectile/Projectile.tscn")


func create_projectile(target: Unit, position: Vector2, speed: int, radius: int, texture: Texture):
	var projectile = projectile_scene.instance()
	projectile.setup(target, position, speed, radius, texture)
	get_tree().get_root().add_child(projectile)
	
	return projectile
