@tool
extends Panel

signal loaded_texture(texture)
signal load_multiple_textures(textures)

const TOOLTIP = preload("res://addons/picky-pixels/ui/tooltip/tooltip.tscn")
const TOOLTIP_EXPLANATION = "Drag and drop texture file(s). If dropping multiple files, they will be applied to multiple light levels, starting at level 0, based on alphabetical order."

@onready var texture_rect = $TextureRect
@onready var label = $Label
@onready var remove_button = $RemoveButton
@onready var zoom_in_button = $ZoomInButton
@onready var zoom_out_button = $ZoomOutButton
var png_regex: RegEx
var image_size: Vector2i
var zoom_percent: float = 1.0


func get_texture() -> Texture2D:
	return texture_rect.texture


func set_texture(texture):
	if texture != null:
		_set_non_null_texture(texture)
	else:
		_reset()


func _set_non_null_texture(texture: Texture2D):
	# Adjust enabled/visible nodes
	label.visible = false
	remove_button.visible = true
	remove_button.disabled = false
	zoom_in_button.visible = true
	zoom_in_button.disabled = false
	zoom_out_button.visible = true
	zoom_out_button.disabled = false
	
	# Update data to display
	texture_rect.texture = texture
	image_size = Vector2i(texture.get_size())
	tooltip_text = "(" + texture.resource_path + ")\n\n" + TOOLTIP_EXPLANATION
	
	# Center the image and zoom based on the new image
	_adjust_zoom()


func _reset():
	label.visible = true
	remove_button.visible = false
	remove_button.disabled = true
	zoom_in_button.visible = false
	zoom_in_button.disabled = true
	zoom_out_button.visible = false
	zoom_out_button.disabled = true
	tooltip_text = TOOLTIP_EXPLANATION
	texture_rect.texture = null


func _ready():
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Set icons
	remove_button.icon = get_theme_icon("Remove", "EditorIcons")
	zoom_in_button.icon = get_theme_icon("ZoomMore", "EditorIcons")
	zoom_out_button.icon = get_theme_icon("ZoomLess", "EditorIcons")
	png_regex = RegEx.new()
	png_regex.compile(".*\\.png$")
	_reset()


func _adjust_zoom():
	var new_size = image_size * zoom_percent
	var half_new_size = Vector2i(new_size / 2.0)
	texture_rect.offset_left = -1 * half_new_size.x
	texture_rect.offset_top = -1 * half_new_size.y
	texture_rect.offset_right = half_new_size.x
	texture_rect.offset_bottom = half_new_size.y


func _make_custom_tooltip(for_text):
	var tooltip_node = TOOLTIP.instantiate()
	tooltip_node.text = for_text
	return tooltip_node


func _can_drop_data(at_position, data):
	return (
		typeof(data) == TYPE_DICTIONARY and
		data.has("files") and
		typeof(data.files) == TYPE_PACKED_STRING_ARRAY and
		data.files.size() > 0 and
		Array(data.files).all(func(file): return png_regex.search(file) != null)
	)


func _drop_data(at_position, data):
	if data.files.size() == 1:
		var texture = load(data.files[0])
		_set_non_null_texture(texture)
		loaded_texture.emit(texture)
	else:
		load_multiple_textures.emit(data.files)


func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_percent *= 1.1
			_adjust_zoom()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_percent /= 1.1
			_adjust_zoom()


func _on_remove_button_pressed():
	_reset()
	loaded_texture.emit(null)


func _on_zoom_out_button_pressed():
	zoom_percent /= 1.25
	_adjust_zoom()


func _on_zoom_in_button_pressed():
	zoom_percent *= 1.25
	_adjust_zoom()
