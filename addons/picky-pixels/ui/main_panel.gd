@tool
extends VBoxContainer

const TEXTURE_EDITOR = preload("res://addons/picky-pixels/ui/texture_editor/texture_editor.tscn")

@onready var _library = $TabContainer/Library
@onready var _main_tab_bar = $HBoxContainer/MainTabBar
@onready var _tab_container = $TabContainer
var _tab_to_resource: Array[Resource] = [null]

func _ready():
	PickyPixelsManager.get_instance().updated.connect(_on_picky_pixels_manager_updated)


func _on_picky_pixels_manager_updated():
	var manager = PickyPixelsManager.get_instance()
	# Update the names of tabs and
	# Remove any tabs for resources that have been deleted
	for i in range(_tab_to_resource.size()-1, 0, -1):
		var resource = _tab_to_resource[i]
		# Remove any resources that are no longer managed by the project
		if not manager.has_texture(resource):
			_main_tab_bar.remove_tab(i)
			_tab_to_resource.pop_at(i)
			_tab_container.get_child(i).queue_free()
		# Else, update the names of tabs as needed
		else:
			_main_tab_bar.set_tab_title(i, resource.resource_name)


func _on_library_edit_selected(resource: Resource):
	# Do nothing if resource is not valid for exiting
	if not PickyPixelsManager.is_valid_resource(resource):
		push_warning("Attempted to open an invalid Resource. This is likely due to a plugin bug.")
		return
	
	var tab = _tab_to_resource.find(resource)
	if tab == -1:
		_main_tab_bar.add_tab(resource.resource_name)
		_tab_to_resource.push_back(resource)
		
		# Create new editor and open it
		var new_editor = TEXTURE_EDITOR.instantiate()
		new_editor.texture = resource
		_tab_container.add_child(new_editor)
		
		var new_tab = _tab_to_resource.size() - 1
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
	_tab_to_resource.pop_at(tab)
	var editor = _tab_container.get_child(tab)
	_tab_container.remove_child(editor)
	editor.queue_free()
	
	_library.buttons_disabled = _tab_to_resource.size() > 1
