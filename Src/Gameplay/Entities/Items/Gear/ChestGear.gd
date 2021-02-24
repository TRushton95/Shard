extends Gear
class_name ChestGear

export var torso_sprite : Texture
export var arms_sprite : Texture


func ready() -> void:
	slot = Enums.GearSlotType.CHEST
