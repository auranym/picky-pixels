@tool
extends Panel

signal texture_changed(texture)

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
	tooltip_text = texture.resource_path
	
	# Center the image and zoom based on the new image
	_adjust_zoom()
	
	texture_changed.emit(texture)


func _reset():
	label.visible = true
	remove_button.visible = false
	remove_button.disabled = true
	zoom_in_button.visible = false
	zoom_in_button.disabled = true
	zoom_out_button.visible = false
	zoom_out_button.disabled = true
	tooltip_text = ""
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


func _can_drop_data(at_position, data):
	return (
		typeof(data) == TYPE_DICTIONARY and
		data.has("files") and
		typeof(data.files) == TYPE_PACKED_STRING_ARRAY and
		data.files.size() == 1 and 
		png_regex.search(data.files[0]) != null
	)


func _drop_data(at_position, data):
	_set_non_null_texture(
		load(data.files[0])
	)


func _on_remove_button_pressed():
	_reset()
	texture_changed.emit(null)


func _on_zoom_out_button_pressed():
	zoom_percent /= 1.25
	_adjust_zoom()


func _on_zoom_in_button_pressed():
	zoom_percent *= 1.25
	_adjust_zoom()
