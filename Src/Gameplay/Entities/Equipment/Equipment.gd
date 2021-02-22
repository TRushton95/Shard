extends Node

signal item_equipped(gear)
signal item_unequipped(gear)


func try_equip_gear(gear: Gear, slot_type: int) -> bool:
	if gear.slot != slot_type:
		print("Cannot equip item to that slot")
		return false
	
	var slot = get_slot(slot_type)
	
	if slot.get_child_count() > 0:
		unequip_gear(gear.slot)
		
	slot.add_child(gear)
	emit_signal("item_equipped", gear)
	
	return true

func unequip_gear(slot_type: int) -> Gear:
	var result = null
	
	var slot = get_slot(slot_type)
	if slot.get_child_count() > 0:
		result = slot.get_child(0)
		slot.remove_child(result)
		emit_signal("item_unequipped", result)
		
	return result


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
