@tool
extends HFlowContainer

const SPRITE_ITEM = preload("res://addons/picky-pixels/ui/library/sprite_item.tscn")

var _project_data: PickyPixelsProjectData = null
@export var project_data: PickyPixelsProjectData:
	get: return _project_data
	set(d):
		if not is_inside_tree():
			await ready
		_project_data = d
		_import_project_data()


func _import_project_data():
	for child in get_children():
		remove_child(child)
	
	if _project_data == null:
		return
	
	for sprite in _project_data.sprites:
		if sprite == null:
			continue
		
		var sprite_item = SPRITE_ITEM.instantiate()
		sprite_item.data = sprite
		add_child(sprite_item)
