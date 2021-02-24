extends Node

signal item_equipped(gear)
signal item_unequipped(gear)


func equip_gear(gear: Gear, gear_slot_type: int) -> bool:
	if !gear:
		return false
	
	if gear.slot != gear_slot_type:
		print("Cannot equip item to that slot")
		return false
	
	var slot = get_slot(gear_slot_type)
	
	if slot.get_child_count() > 0:
		print("Gear slot is already equipped")
		return false
		
	slot.add_child(gear)
	emit_signal("item_equipped", gear)
	
	return true

func unequip_gear(gear_slot_type: int) -> Gear:
	var result = null
	
	var slot = get_slot(gear_slot_type)
	if slot.get_child_count() > 0:
		result = slot.get_child(0)
		slot.remove_child(result)
		emit_signal("item_unequipped", result)
		
	return result


func get_slot(gear_slot_type: int) -> Node:
	var result
	
	match gear_slot_type:
		Enums.GearSlotType.HEAD:
			result = $HeadSlot
		Enums.GearSlotType.CHEST:
			result = $ChestSlot
		Enums.GearSlotType.LEGS:
			result = $LegsSlot
		Enums.GearSlotType.FEET:
			result = $FeetSlot
		Enums.GearSlotType.HANDS:
			result = $HandsSlot
		Enums.GearSlotType.WEAPON:
			result = $WeaponSlot
			
	return result
