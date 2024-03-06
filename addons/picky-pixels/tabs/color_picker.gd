@tool
extends Control

@onready var _label_node: Label = $Label
@onready var _color_picker_button = $ColorPickerButton

var _label: String = "Color 1"
@export var label: String = "Color 1":
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
		_color = val
		if _color_picker_button == null:
			await ready
		_color_picker_button.color = val

func _on_color_picker_button_color_changed(c):
	_color = c
