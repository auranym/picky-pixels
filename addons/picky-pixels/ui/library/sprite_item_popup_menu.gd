@tool
extends PopupMenu

signal rename_pressed
signal delete_pressed

# Called when the node enters the scene tree for the first time.
func _ready():
	set_item_icon(0, get_theme_icon("Rename", "EditorIcons"))
	set_item_icon(1, get_theme_icon("Remove", "EditorIcons"))


func _on_id_pressed(id):
	match id:
		0: rename_pressed.emit()
		1: delete_pressed.emit()
