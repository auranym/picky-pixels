@tool
extends TextureRect

@onready var label = $Label
@onready var remove_button = $RemoveButton
var png_regex: RegEx

func _reset():
	label.visible = true
	remove_button.visible = false
	remove_button.disabled = true
	tooltip_text = ""
	texture = null

func _ready():
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	remove_button.icon = get_theme_icon("Remove", "EditorIcons")
	png_regex = RegEx.new()
	png_regex.compile(".*\\.png$")
	_reset()

func _can_drop_data(at_position, data):
	return (
		typeof(data) == TYPE_DICTIONARY and
		data.has("files") and
		typeof(data.files) == TYPE_PACKED_STRING_ARRAY and
		data.files.size() == 1 and 
		png_regex.search(data.files[0]) != null
	)

func _drop_data(at_position, data):
	label.visible = false
	remove_button.visible = true
	remove_button.disabled = false
	var image_path = data.files[0]
	tooltip_text = image_path
	texture = load(image_path)

func _on_remove_button_pressed():
	_reset()
