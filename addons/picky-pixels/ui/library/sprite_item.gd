@tool
extends Control

signal edit_selected
signal delete_selected

const TOOLTIP = preload("res://addons/picky-pixels/ui/tooltip/tooltip.tscn")

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
@onready var no_textures_texture_rect = $NoTexturesTextureRect
@onready var label = $Label
@onready var text_edit = $TextEdit
@onready var sprite_item_popup_menu = $SpriteItemPopupMenu
@onready var _tooltip_text = tooltip_text

var _mouse_within = false


func _ready():
	panel.visible = false
	text_edit.visible = false
	sprite_item_popup_menu.visible = false
	no_textures_texture_rect.texture = get_theme_icon("Sprite2D", "EditorIcons")
	no_textures_texture_rect.visible = false
	_generate_texture()
	_update_label()


func _generate_texture():
	if (
		_data == null or
		_data.base_textures == null or
		_data.base_textures.size() == 0 or 
		_data.base_textures.back() == null
	):
		texture_rect.texture = null
		no_textures_texture_rect.visible = true
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
		no_textures_texture_rect.visible = false
		texture_rect.texture = ImageTexture.create_from_image(library_image)


func _update_label():
	if _data == null or _data.name == null:
		label.text = ""
	else:
		label.text = _data.name
	text_edit.text = label.text


func _hide_text_edit():
	label.text = text_edit.text
	text_edit.visible = false
	text_edit.editable = false
	label.visible = true
	tooltip_text = _tooltip_text
	
	# Update data
	_data.name = label.text
	
	if _mouse_within:
		panel.visible = true



func _get_drag_data(at_position):
	return {
		"type": "resource",
		"resource": _data
	}


func _gui_input(event):
	# Regardless of input, first check if we need to hide
	# the text_edit (renaming)
	if (
		event is InputEventMouseButton and
		(
			event.button_index == MOUSE_BUTTON_RIGHT or
			event.button_index == MOUSE_BUTTON_LEFT
		) and
		text_edit.has_focus()
	):
		_hide_text_edit()
	
	if (
		event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT
	):
		sprite_item_popup_menu.position = global_position + Vector2(8, size.y)
		sprite_item_popup_menu.visible = true
	elif (
		event is InputEventMouseButton and
		event.button_index == MOUSE_BUTTON_LEFT and 
		event.double_click
	):
		edit_selected.emit()


func _make_custom_tooltip(for_text):
	var tooltip_node = TOOLTIP.instantiate()
	tooltip_node.text = for_text
	return tooltip_node


func _on_mouse_entered():
	if not text_edit.has_focus():
		panel.visible = true
	_mouse_within = true


func _on_mouse_exited():
	if not sprite_item_popup_menu.visible:
		panel.visible = false
	_mouse_within = false


func _on_sprite_item_popup_menu_popup_hide():
	if not _mouse_within:
		panel.visible = false


func _on_sprite_item_popup_menu_edit_pressed():
	edit_selected.emit()


func _on_sprite_item_popup_menu_rename_pressed():
	text_edit.visible = true
	text_edit.editable = true
	label.visible = false
	tooltip_text = ""
	text_edit.set_caret_column(text_edit.text.length())
	text_edit.grab_focus()


func _on_sprite_item_popup_menu_delete_pressed():
	delete_selected.emit()


func _on_text_edit_focus_exited():
	_hide_text_edit()


func _on_text_edit_gui_input(event):
	if (
		text_edit.has_focus() and
		event is InputEventKey and
		(
			event.keycode == KEY_ENTER or 
			event.keycode == KEY_ESCAPE
		)
	):
			_hide_text_edit()
