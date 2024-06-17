@tool
extends VBoxContainer

signal edit_selected(index: int)

const SPRITE_ITEM = preload("res://addons/picky-pixels/ui/library/sprite_item.tscn")

var _project_data: PickyPixelsProjectData = null
@export var project_data: PickyPixelsProjectData:
	get: return _project_data
	set(d):
		if _project_data != null:
			_project_data.changed.disconnect(_import_project_data)
		
		if not is_inside_tree():
			await ready
		
		_project_data = d
		_project_data.changed.connect(_import_project_data)
		_import_project_data()

@onready var color_palette = $ColorPalette
@onready var item_container = $ItemContainer
@onready var new_item = $ItemContainer/NewItem


func _import_project_data():
	for child in item_container.get_children():
		if not child == new_item:
			item_container.remove_child(child)
	
	if _project_data == null:
		return
	
	for i in _project_data.sprites.size():
		var sprite = _project_data.sprites[i]
		if sprite == null:
			continue
		
		var sprite_item = SPRITE_ITEM.instantiate()
		sprite_item.data = sprite
		sprite_item.edit_selected.connect(func(): _on_sprite_item_edit_selected(i))
		sprite_item.delete_selected.connect(func(): _on_sprite_item_delete_selected(i))
		item_container.add_child(sprite_item)
	
	item_container.move_child(new_item, -1)
	
	color_palette.colors = _project_data.palette


func _on_new_item_clicked():
	_project_data.create_sprite()


func _on_sprite_item_edit_selected(index: int):
	edit_selected.emit(index)


func _on_sprite_item_delete_selected(index: int):
	_project_data.delete_sprite(index)
