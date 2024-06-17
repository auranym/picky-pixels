@tool
extends VBoxContainer

const DEFAULT_PROJECT = "res://picky_pixels_project_data.res"

@onready var _texture_editor = $TabContainer/TextureEditor
@onready var _library = $TabContainer/Library
var _project_data: PickyPixelsProjectData

# DATA MUTATION SOURCES:
# - Sprite create: library
# - Sprite edit: TODO
# - Sprite rename: library/sprite_item
# - Sprite delete: TODO

func _ready():
	if ResourceLoader.exists(
		DEFAULT_PROJECT,
		"PickyPixelsProjectData"
	):
		_project_data = load(DEFAULT_PROJECT)
		print("Loaded PickyPixels project (%s)" % DEFAULT_PROJECT)
	# Create project if it does not yet exist
	else:
		_project_data = PickyPixelsProjectData.new()
		_project_data.resource_path = DEFAULT_PROJECT
		ResourceSaver.save(_project_data)
		print("Created new PickyPixels project (%s)" % DEFAULT_PROJECT)
	
	_texture_editor.project_data = _project_data
	_library.project_data = _project_data


func _on_library_edit_selected(index):
	print("edit " + str(index))
