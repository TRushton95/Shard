extends Node

signal item_equipped(gear)
signal item_unequipped(gear)


func equip_gear(gear: Gear, slot_type: int) -> void:
	if gear.slot != slot_type:
		print("Cannot equip item to that slot")
		return
	
	var slot = get_slot(slot_type)
	
	if slot.get_child_count() > 0:
		unequip_gear(gear.slot)
		
	slot.add_child(gear)
	emit_signal("item_equipped", gear)

func unequip_gear(slot_type: int) -> void:
	var slot = get_slot(slot_type)
	
	if slot.get_child_count() > 0:
		var item = slot.get_child(0)
		item.remove_child(item)
		emit_signal("item_unequipped", item)


func get_slot(slot_type: int) -> Node:
	var result
	
	match slot_type:
		Enums.GearSlot.HEAD:
			result = $HeadSlot
		Enums.GearSlot.CHEST:
			result = $ChestSlot
		Enums.GearSlot.LEGS:
			result = $LegsSlot
		Enums.GearSlot.FEET:
			result = $FeetSlot
		Enums.GearSlot.HANDS:
			result = $HandsSlot
		Enums.GearSlot.WEAPON:
			result = $WeaponSlot
			
	return result
