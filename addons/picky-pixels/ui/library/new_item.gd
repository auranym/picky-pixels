@tool
extends Control

signal clicked

@onready var _texture_rect = $TextureRect
@onready var _panel = $Panel


func _ready():
	_texture_rect.texture = get_theme_icon("New", "EditorIcons")
	_panel.visible = false


func _on_mouse_entered():
	_panel.visible = true


func _on_mouse_exited():
	_panel.visible = false


func _on_gui_input(event):
	if (
		event is InputEventMouseButton and
		event.button_index == MOUSE_BUTTON_LEFT and
		event.pressed
	):
		clicked.emit()
