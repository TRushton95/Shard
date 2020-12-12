extends Node

export var size := 4


func _ready() -> void:
	for i in size:
		var slot = Node.new()
		slot.name = "Slot" + str(i)
		add_child(slot)


func push_item(item: Node, index := -1) -> bool:
	var slot
	
	if index > -1 && index < get_child_count():
		slot = get_child(index)
	else:
		slot = _get_free_slot()
	
	if !slot:
		print("Inventory is full")
		return false
		
	slot.add_child(item)
	return true


func get_item(index: int) -> Item:
	var result
	
	var slot = get_child(index)
	if slot.get_child_count() > 0:
		result = slot.get_child(0)
		
	return result


func pop_item(index: int) -> Item:
	var result
	
	var slot = get_child(index)
	if slot.get_child_count() > 0:
		result = slot.get_child(0)
		slot.remove_child(result)
		
	return result


func move(from_index: int, to_index: int) -> void:
	if _is_slot_free(from_index):
		print("No item at slot")
		return
		
	var from_item = pop_item(from_index)
	
	var to_item = pop_item(to_index)
	if to_item:
		push_item(to_item, from_index)
		
	push_item(from_item, to_index)


func _is_slot_free(index: int) -> bool:
	return get_child(index).get_child_count() == 0


func _get_free_slot() -> ButtonSlot:
	for slot in get_children():
		if slot.get_child_count() == 0:
			return slot
			
	return null
