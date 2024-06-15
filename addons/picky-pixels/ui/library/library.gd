@tool
extends VBoxContainer

const SPRITE_ITEM = preload("res://addons/picky-pixels/ui/library/sprite_item.tscn")

var _project_data: PickyPixelsProjectData = null
@export var project_data: PickyPixelsProjectData:
	get: return _project_data
	set(d):
		if not is_inside_tree():
			await ready
		_project_data = d
		_import_project_data()

@onready var color_palette = $ColorPalette
@onready var item_container = $ItemContainer


func _import_project_data():
	for child in item_container.get_children():
		item_container.remove_child(child)
	
	if _project_data == null:
		return
	
	for sprite in _project_data.sprites:
		if sprite == null:
			continue
		
		var sprite_item = SPRITE_ITEM.instantiate()
		sprite_item.data = sprite
		item_container.add_child(sprite_item)
	
	color_palette.colors = _project_data.palette
