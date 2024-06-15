@tool
extends PopupMenu

signal edit_pressed
signal rename_pressed
signal delete_pressed

# Called when the node enters the scene tree for the first time.
func _ready():
	set_item_icon(0, get_theme_icon("Edit", "EditorIcons"))
	set_item_icon(1, get_theme_icon("Rename", "EditorIcons"))
	set_item_icon(2, get_theme_icon("Remove", "EditorIcons"))


func _on_id_pressed(id):
	match id:
		0: edit_pressed.emit()
		1: rename_pressed.emit()
		2: delete_pressed.emit()
