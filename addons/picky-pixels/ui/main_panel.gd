@tool
extends VBoxContainer

# Scenes
const TEXTURE_EDITOR = preload("res://addons/picky-pixels/ui/texture_editor/texture_editor.tscn")

@onready var _library = $TabContainer/Library
@onready var _main_tab_bar = $HBoxContainer/MainTabBar
@onready var _tab_container = $TabContainer
var _tab_to_resource = [null]

func _ready():
	PickyPixelsManager.instance.updated.connect(_on_picky_pixels_manager_updated)
	_library.edit_selected.connect(_on_library_edit_selected)


func _on_picky_pixels_manager_updated():
	pass






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
