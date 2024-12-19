@tool
extends Panel

signal edit_pressed
signal rename_pressed
signal delete_pressed

@onready var _edit_button: Button = $VBoxContainer/EditButton
@onready var _rename_button: Button = $VBoxContainer/RenameButton
@onready var _delete_button: Button = $VBoxContainer/DeleteButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_edit_button.icon = get_theme_icon("Edit", "EditorIcons")
	_rename_button.icon = get_theme_icon("Rename", "EditorIcons")
	_delete_button.icon = get_theme_icon("Remove", "EditorIcons")


func _on_edit_button_pressed() -> void:
	edit_pressed.emit()


func _on_rename_button_pressed() -> void:
	rename_pressed.emit()


func _on_delete_button_pressed() -> void:
	delete_pressed.emit()
