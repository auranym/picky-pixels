@tool
extends Control

signal color_changed(c: Color)

@onready var _label_node: Label = $Label
@onready var _color_picker_button = $ColorPickerButton
@onready var _copy_confirm_panel: PopupPanel = $CopyConfirmPanel


var _label: String = "0"
@export var label: String = "0":
	get: return _label
	set(val):
		_label = val
		if not is_inside_tree():
			await ready
		_label_node.text = val

var _color: Color
@export var color: Color:
	get: return _color
	set(val):
		if _color == val:
			return
		_color = val
		if not is_inside_tree():
			await ready
		var hex_code = _color.to_html().substr(0, 6)
		tooltip_text = "#" + hex_code + " (Right click to copy)"
		_copy_confirm_panel.hex_code = hex_code
		_color_picker_button.color = val
		color_changed.emit(val)

var _color_locked: bool
## Whether the color can be edited by the user.
@export var color_locked: bool = false:
	get: return _color_locked
	set(val):
		_color_locked = val
		if not is_inside_tree():
			await ready
		_color_picker_button.disabled = color_locked


func _ready():
	_copy_confirm_panel.visible = false


func _on_color_picker_button_color_changed(c):
	_color = c


func _on_gui_input(event):
	if (
		event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT
	):
		_copy_confirm_panel.position = global_position
		_copy_confirm_panel.visible = true


func _on_copy_confirm_panel_pressed() -> void:
	_copy_confirm_panel.visible = false
	var hex_code = _color.to_html().substr(0, 6)
	DisplayServer.clipboard_set(hex_code)
	print("Copied hex code #" + hex_code + " to clipboard.")
