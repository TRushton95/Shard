extends Node
class_name ActionLookup

var source := -1
var index := -1


func _init(source: int, index: int) -> void:
	self.source = source
	self.index = index
