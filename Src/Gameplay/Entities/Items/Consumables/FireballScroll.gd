extends Item

func get_ability() -> Ability:
	return get_node("Fireball") as Ability
