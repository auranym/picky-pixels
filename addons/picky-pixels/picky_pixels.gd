@tool
extends EditorPlugin

# Reference:
# https://docs.godotengine.org/en/stable/tutorials/plugins/editor/making_main_screen_plugins.html
# https://forum.godotengine.org/t/how-can-i-implement-drag-and-drop-into-the-scene-from-my-editorplugin/3804/2

const MainPanel = preload("res://addons/picky-pixels/ui/main_panel.tscn")

var main_panel_instance


func _enter_tree():
	main_panel_instance = MainPanel.instantiate()
	# Add the main panel to the editor's main viewport.
	EditorInterface.get_editor_main_screen().add_child(main_panel_instance)
	# Hide the main panel. Very much required.
	_make_visible(false)


func _exit_tree():
	if main_panel_instance:
		main_panel_instance.queue_free()


func _has_main_screen():
	return true


func _make_visible(visible):
	if main_panel_instance:
		main_panel_instance.visible = visible


func _get_plugin_name():
	return "PickyPixels"


func _get_plugin_icon():
	# Must return some kind of Texture for the icon.
	return EditorInterface.get_editor_theme().get_icon("Node", "EditorIcons")
