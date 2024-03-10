@tool
extends Control

signal color_changed(c: Color)

@onready var _label_node: Label = $Label
@onready var _color_picker_button = $ColorPickerButton

var _label: String = "0"
@export var label: String = "0":
	get: return _label
	set(val):
		_label = val
		if _label_node == null:
			await ready
		_label_node.text = val

var _color: Color
@export var color: Color:
	get: return _color
	set(val):
		if _color == val:
			return
		_color = val
		if _color_picker_button == null:
			await ready
		_color_picker_button.color = val
		color_changed.emit(val)

var _color_locked: bool
## Whether the color can be edited by the user.
@export var color_locked: bool = false:
	get: return _color_locked
	set(val):
		_color_locked = val
		if _color_picker_button == null:
			await ready
		_color_picker_button.disabled = true

func _on_color_picker_button_color_changed(c):
	_color = c
