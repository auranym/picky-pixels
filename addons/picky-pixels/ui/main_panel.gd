@tool
extends VBoxContainer

const TEXTURE_EDITOR = preload("res://addons/picky-pixels/ui/texture_editor/texture_editor.tscn")

@onready var _library = $TabContainer/Library
@onready var _main_tab_bar = $HBoxContainer/MainTabBar
@onready var _tab_container = $TabContainer


func _ready():
	PickyPixelsManager.get_instance().updated.connect(_on_picky_pixels_manager_updated)

# For now, since only ImageTextures are the only type of
# Resource, only support those.

func _get_resource(tab: int) -> PickyPixelsImageTexture:
	var resource = _tab_container.get_child(tab).texture
	if resource is PickyPixelsImageTexture:
		return resource
	else:
		return null


func _get_tab_for_resource(resource: PickyPixelsImageTexture) -> int:
	for i in range(1, _tab_container.get_tab_count()):
		if _tab_container.get_child(i).texture == resource:
			return i
	return -1


func _on_picky_pixels_manager_updated():
	var manager = PickyPixelsManager.get_instance()
	
	# Update the names of tabs and
	# Remove any tabs for resources that have been deleted.
	for i in range(1, _tab_container.get_tab_count()):
		var editor = _tab_container.get_child(i)
		var resource = editor.texture
		
		if resource is not PickyPixelsImageTexture:
			push_error("Error: Found unknown Resource type when refreshing library tabs. This is a bug with the plugin.")
		
		if not manager.has_texture(resource):
			editor.queue_free()
			# I don't know why, but this needs to be deferred, since
			# otherwise results in an off-by-one error.
			# I'm pretty sure this is a bug in Godot's source code.
			# TODO file a bug...
			_main_tab_bar.call_deferred("remove_tab", i)
		else:
			var tab_title = resource.resource_name
			if editor.has_changes():
				tab_title += "(*)"
			_main_tab_bar.set_tab_title(i, tab_title)


func _on_library_edit_selected(resource: Resource):
	# Do nothing if resource is not valid for exiting
	if not PickyPixelsManager.is_valid_resource(resource):
		push_warning("Attempted to open an invalid Resource. This is likely due to a plugin bug.")
		return
	
	var tab = _get_tab_for_resource(resource)
	if tab == -1:
		_main_tab_bar.add_tab(resource.resource_name)
		
		# Create new editor and open it
		var new_editor = TEXTURE_EDITOR.instantiate()
		new_editor.texture = resource
		new_editor.no_changes.connect(_hide_change_indicator)
		new_editor.made_changes.connect(_show_change_indicator)
		_tab_container.add_child(new_editor)
		
		var new_tab = _tab_container.get_tab_count() - 1
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
	var editor = _tab_container.get_child(tab)
	_tab_container.remove_child(editor)
	editor.queue_free()
	
	_library.buttons_disabled = _tab_container.get_tab_count() > 1


func _show_change_indicator(texture: PickyPixelsImageTexture):
	var tab = _get_tab_for_resource(texture)
	
	# Not sure if/when this will be reached, but just in case...
	if tab == -1:
		return
	
	_main_tab_bar.set_tab_title(tab, texture.resource_name + "(*)")


func _hide_change_indicator(texture: PickyPixelsImageTexture):
	var tab = _get_tab_for_resource(texture)
	
	# This can be reached when creating the new texture editor instance.
	if tab == -1:
		return
	
	_main_tab_bar.set_tab_title(tab, texture.resource_name)
