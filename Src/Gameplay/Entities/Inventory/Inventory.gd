# TODO: Add static typing to this file once Item is implemented
extends Node

export var size := 4


func _ready() -> void:
	for i in size:
		var slot = Node.new()
		slot.name = "Slot" + str(i)
		add_child(slot)


func push_item(item: Node) -> bool:
	var slot = _get_free_slot()
	
	if !slot:
		print("Inventory is full")
		return false
		
	
	slot.add_child(item)
	return true


func get_item(index: int):
	var result
	
	var slot = get_child(index)
	if slot.get_child_count() > 0:
		result = slot.get_child(0)
		
	return result


func pop_item(index: int):
	var result
	
	var slot = get_child(index)
	if slot.get_child_count() > 0:
		result = slot.get_child(0)
		slot.remove_child(result)
		
	return result


func _get_free_slot():
	for slot in get_children():
		if slot.get_child_count() == 0:
			return slot
			
	return null
