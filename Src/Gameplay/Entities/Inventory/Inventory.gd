# TODO: Add static typing to this file once Item is implemented
extends Node

export var size := 20

var _slots := []

func _ready() -> void:
	for i in range(20):
		_slots.resize(size)


func push_item(item) -> void:
	var slot_index = _get_free_slot_index()
	
	if slot_index == -1:
		print("Inventory is full")
		return
		
	_slots[slot_index] = item


func get_item(index: int):
	var result
	
	if index < _slots.size():
		var item = _slots[index]
		result = item
		
	return result


func pop_item(index: int):
	var result = get_item(index)
	
	if result:
		_slots.remove(index)
		
	return result


func _get_free_slot_index() -> int:
	for i in range(_slots.size()):
		if !_slots[i]:
			return i
			
	return -1
