@tool
extends HFlowContainer

const SPRITE_ITEM = preload("res://addons/picky-pixels/ui/library/sprite_item.tscn")
const GENERATED_RESOURCE = preload("res://test/generated_resource.res")

func _ready():
	# temp
	var item = SPRITE_ITEM.instantiate()
	item.data = GENERATED_RESOURCE
	add_child(item)
