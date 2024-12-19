@tool
extends Control

signal edit_selected

const TOOLTIP = preload("res://addons/picky-pixels/ui/tooltip/tooltip.tscn")
const TOOLTIP_TEXT = "({file})\n\nDrag and drop into any Texture2D property (such as a Sprite2D). Right click to show options."
const WARNING_TOOLTIP_TEXT = "This texture had issues after recompiling. Edit to resolve them."


@export var texture: PickyPixelsImageTexture:
	get: return texture
	set(val):
		texture = val
		if not is_node_ready():
			await ready
		
		_generate_texture()
		_update_label()
		
		# Show or hide warning
		warning_texture_rect.visible = texture.invalid_textures
		if texture.invalid_textures:
			tooltip_text = WARNING_TOOLTIP_TEXT
			no_textures_texture_rect.visible = false
		else:
			tooltip_text = TOOLTIP_TEXT.format({ "file": texture.resource_path })
			if _show_no_texture_icon():
				no_textures_texture_rect.visible = true

@onready var panel = $Panel
@onready var texture_rect = $TextureRect
@onready var no_textures_texture_rect = $NoTexturesTextureRect
@onready var label = $Label
@onready var text_edit = $TextEdit
@onready var texture_item_options = $TextureItemOptions
@onready var warning_texture_rect = $WarningTextureRect
@onready var _tooltip_text = tooltip_text

var _mouse_within = false


func _ready():
	panel.visible = false
	text_edit.visible = false
	texture_item_options.visible = false
	no_textures_texture_rect.texture = get_theme_icon("Sprite2D", "EditorIcons")
	no_textures_texture_rect.visible = false
	warning_texture_rect.visible = false


func _show_no_texture_icon():
	return (
		texture == null or
		texture.base_textures == null or
		texture.base_textures.size() == 0 or 
		texture.base_textures.back() == null
	)


func _generate_texture():
	if _show_no_texture_icon():
		texture_rect.texture = null
		no_textures_texture_rect.visible = true
	else:
		# Generate library image by scaling larger dimension to 128
		# and proportionally scaling the other one.
		# This is necessary to ensure correct image scaling.
		# Without manual scaling, it is blurry...
		var base_image: Image = texture.base_textures.back().get_image()
		var width = base_image.get_width()
		var height = base_image.get_height()
		var x = width
		var y = height
		if x > y:
			y = int(floor(128.0 * float(y) / float(x)))
			x = 128
		else:
			x = int(floor(128.0 * float(x) / float(y)))
			y = 128
		# Copying is necessary so that we don't modify the original
		# image resource.
		var library_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
		library_image.copy_from(base_image)
		library_image.resize(x, y, Image.INTERPOLATE_NEAREST)
		no_textures_texture_rect.visible = false
		texture_rect.texture = ImageTexture.create_from_image(library_image)


func _update_label():
	if texture == null or texture.resource_name == null:
		label.text = ""
	else:
		label.text = texture.resource_name
	text_edit.text = label.text


func _hide_text_edit():
	text_edit.visible = false
	text_edit.editable = false
	label.visible = true
	tooltip_text = _tooltip_text
	
	# Update data if new name is valid
	var manager = PickyPixelsManager.get_instance()
	if not manager.is_texture_with_name(text_edit.text):
		label.text = text_edit.text
		manager.rename_texture(texture, text_edit.text)
	else:
		text_edit.text = label.text
	
	if _mouse_within:
		panel.visible = true


func _get_drag_data(at_position):
	# Disable drag and drop if there are any issues
	if texture == null or texture.invalid_textures:
		return {}
	
	return {
		"type": "resource",
		"resource": texture
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
		texture_item_options.position = global_position + Vector2(0, size.y)
		texture_item_options.visible = true
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
	if not texture_item_options.visible:
		panel.visible = false
	_mouse_within = false


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


func _on_texture_item_options_delete_pressed() -> void:
	texture_item_options.visible = false
	PickyPixelsManager.get_instance().delete_texture(texture)


func _on_texture_item_options_edit_pressed() -> void:
	texture_item_options.visible = false
	edit_selected.emit()


func _on_texture_item_options_rename_pressed() -> void:
	texture_item_options.visible = false
	text_edit.visible = true
	text_edit.editable = true
	label.visible = false
	tooltip_text = ""
	text_edit.set_caret_column(text_edit.text.length())
	text_edit.grab_focus()


func _on_texture_item_options_visibility_changed() -> void:
	if not _mouse_within:
		panel.visible = false
