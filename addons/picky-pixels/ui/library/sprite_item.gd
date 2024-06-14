@tool
extends Control

var _data: PickySprite2DData
@export var data: PickySprite2DData:
	get: return _data
	set(d):
		_data = d
		if not is_inside_tree():
			await ready
		_generate_texture()
		_update_label()
		

@onready var panel = $Panel
@onready var texture_rect = $TextureRect
@onready var label = $Label
@onready var sprite_item_popup_menu = $SpriteItemPopupMenu

var _mouse_within = false


func _ready():
	panel.visible = false
	sprite_item_popup_menu.visible = false
	_generate_texture()
	_update_label()


func _generate_texture():
	if _data == null or _data.base_textures == null or _data.base_textures.size() == 0:
		texture_rect.texture = null
	else:
		# Generate library image by scaling larger dimension to 128
		# and proportionally scaling the other one.
		var library_image: Image = _data.base_textures.back().get_image()
		var x = library_image.get_width()
		var y = library_image.get_height()
		if x > y:
			y = int(floor(128.0 * float(y) / float(x)))
			x = 128
		else:
			x = int(floor(128.0 * float(x) / float(y)))
			y = 128
		library_image.resize(x, y, Image.INTERPOLATE_NEAREST)
		texture_rect.texture = ImageTexture.create_from_image(library_image)


func _update_label():
	if _data == null or _data.name == null:
		label.text = ""
	else:
		label.text = _data.name


func _get_drag_data(at_position):
	return {
		"type": "resource",
		"resource": _data
	}


func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		sprite_item_popup_menu.position = global_position + Vector2(8, size.y)
		sprite_item_popup_menu.visible = true



func _on_mouse_entered():
	panel.visible = true
	_mouse_within = true


func _on_mouse_exited():
	if not sprite_item_popup_menu.visible:
		panel.visible = false
	_mouse_within = false


func _on_sprite_item_popup_menu_popup_hide():
	if not _mouse_within:
		panel.visible = false


func _on_sprite_item_popup_menu_rename_pressed():
	print("renamed")


func _on_sprite_item_popup_menu_delete_pressed():
	print("deleted")
