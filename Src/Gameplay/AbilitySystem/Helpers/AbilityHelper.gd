extends Node

var zone_scene = load("res://Gameplay/Entities/Abilities/Zone/Zone.tscn")
var projectile_scene = load("res://Gameplay/Entities/Abilities/Projectile/Projectile.tscn")


func create_zone(position: Vector2, duration: float, tick_rate: float, radius: int, texture: Texture) -> Zone:
	var zone = zone_scene.instance()
	get_tree().get_root().add_child(zone)
	zone.setup(position, duration, tick_rate, radius, texture)
	
	return zone


func create_projectile(target: Unit, position: Vector2, speed: int, radius: int, texture: Texture) -> Projectile:
	var projectile = projectile_scene.instance()
	get_tree().get_root().add_child(projectile)
	projectile.setup(target, position, speed, radius, texture)
	
	return projectile
