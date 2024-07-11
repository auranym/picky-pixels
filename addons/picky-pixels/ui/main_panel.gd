@tool
extends VBoxContainer

const DEFAULT_PROJECT = "res://picky_pixels_project_data.res"
const TEXTURE_EDITOR = preload("res://addons/picky-pixels/ui/texture_editor/texture_editor.tscn")

@onready var _library = $TabContainer/Library
@onready var _main_tab_bar = $HBoxContainer/MainTabBar
@onready var _tab_container = $TabContainer
var _project_data: PickyPixelsProjectData
var _tab_to_sprite = [-1]

# DATA MUTATION SOURCES:
# - Sprite create: library/library
# - Sprite data change: texture_editor/texture_editor
# - Sprite rename: library/sprite_item
# - Sprite delete: library/library
# - Palette change: library/library
# - Recompiling: library/library

func _ready():
	if ResourceLoader.exists(
		DEFAULT_PROJECT,
		"PickyPixelsProjectData"
	):
		_project_data = load(DEFAULT_PROJECT)
		print("Loaded PickyPixels project (%s)" % DEFAULT_PROJECT)
	else:
		# Try to load from file directly if resource loader isn't ready yet
		_project_data = ResourceLoader.load(DEFAULT_PROJECT)
		if _project_data == null:
			# Create project if it does not yet exist
			_project_data = PickyPixelsProjectData.new()
			_project_data.resource_path = DEFAULT_PROJECT
			ResourceSaver.save(_project_data)
			print("Created new PickyPixels project (%s)" % DEFAULT_PROJECT)
		else:
			print("Loaded PickyPixels project (%s)" % DEFAULT_PROJECT)
	
	_project_data.sprite_deleted.connect(_on_project_sprite_deleted)
	
	_library.project_data = _project_data


func _on_project_sprite_deleted(index):
	var tab_to_remove = -1
	
	for tab in _tab_to_sprite.size():
		if _tab_to_sprite[tab] == index:
			tab_to_remove = tab
		# When a sprite is deleted, the indices of later sprites all decrease
		# by 1. So, we must update the index that a tab points to if it
		# is decreased due to a sprite deletion.
		if _tab_to_sprite[tab] > index:
			_tab_to_sprite[tab] -= 1
	
	if tab_to_remove != -1:
		_main_tab_bar.remove_tab(tab_to_remove)
		_tab_to_sprite.pop_at(tab_to_remove)
		var editor = _tab_container.get_child(tab_to_remove)
		_tab_container.remove_child(editor)
		editor.queue_free()


func _on_library_edit_selected(index):
	var tab = _tab_to_sprite.find(index)
	if tab == -1:
		_main_tab_bar.add_tab(_project_data.sprites[index].name)
		_tab_to_sprite.push_back(index)
		
		# Create new editor and open it
		var new_editor = TEXTURE_EDITOR.instantiate()
		new_editor.project_data = _project_data
		new_editor.sprite_index = index
		_tab_container.add_child(new_editor)
		
		var new_tab = _tab_to_sprite.size()-1
		_main_tab_bar.current_tab = new_tab
		_tab_container.current_tab = new_tab
		
		_library.buttons_disabled = true
	else:
		_main_tab_bar.current_tab = tab
		_tab_container.current_tab = tab


func _on_main_tab_bar_tab_clicked(tab):
	_tab_container.current_tab = tab


func _on_main_tab_bar_tab_close_pressed(tab):
	_main_tab_bar.remove_tab(tab)
	_tab_to_sprite.pop_at(tab)
	var editor = _tab_container.get_child(tab)
	_tab_container.remove_child(editor)
	editor.queue_free()
	
	_library.buttons_disabled = _tab_to_sprite.size() > 1
