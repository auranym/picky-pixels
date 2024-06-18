@tool
extends VBoxContainer

const DEFAULT_PROJECT = "res://picky_pixels_project_data.res"

@onready var _texture_editor = $TabContainer/TextureEditor
@onready var _library = $TabContainer/Library
@onready var _main_tab_bar = $HBoxContainer/MainTabBar
var _project_data: PickyPixelsProjectData
var _tab_to_sprite = [-1]

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
	
	_project_data.sprite_deleted.connect(_on_project_sprite_deleted)
	
	_texture_editor.project_data = _project_data
	_library.project_data = _project_data


func _on_project_sprite_deleted(index):
	var tab_to_remove
	
	for tab in _tab_to_sprite.size():
		if _tab_to_sprite[tab] == index:
			tab_to_remove = tab
		# When a sprite is deleted, the indices of later sprites all decrease
		# by 1. So, we must update the index that a tab points to if it
		# is decreased due to a sprite deletion.
		if _tab_to_sprite[tab] > index:
			_tab_to_sprite[tab] -= 1
	
	_main_tab_bar.remove_tab(tab_to_remove)
	_tab_to_sprite.pop_at(tab_to_remove)


func _on_library_edit_selected(index):
	if not _tab_to_sprite.has(index):
		print("created new tab for " + _project_data.sprites[index].name)
		_main_tab_bar.add_tab(_project_data.sprites[index].name)
		_tab_to_sprite.push_back(index)
	else:
		print("selected tab for " + _project_data.sprites[index].name)


func _on_main_tab_bar_tab_clicked(tab):
	if tab == 0:
		print("selected library")
	else:
		print("selected tab for " + _project_data.sprites[_tab_to_sprite[tab]].name)


func _on_main_tab_bar_tab_close_pressed(tab):
	_main_tab_bar.remove_tab(tab)
	_tab_to_sprite.pop_at(tab)
