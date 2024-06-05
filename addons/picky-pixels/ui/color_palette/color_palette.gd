@tool
extends Control

const COLOR_PICKER = preload("res://addons/picky-pixels/ui/color_palette/color_picker.tscn")
@onready var color_picker_container = $ScrollContainer/ColorPickerContainer


var _colors: Array[Color] = []
@export var colors: Array[Color] = []:
	get: return _colors
	set(val):
		_colors = val
		if color_picker_container == null:
			await ready
		# Add/update colors to color_picker_container as needed
		for i in _colors.size():
			var color = _colors[i]
			# If there is an existing color picker, update the color
			if i < color_picker_container.get_child_count():
				color_picker_container.get_child(i).color = color
			# If there is not, create a new color picker
			else:
				var color_picker = COLOR_PICKER.instantiate()
				color_picker.label = str(i)
				color_picker.color = color
				color_picker.color_locked = true
				color_picker_container.add_child(color_picker)
		# Remove any extra color picker nodes, if needed
		for i in range(_colors.size(), color_picker_container.get_child_count()):
			color_picker_container.remove_child(color_picker_container.get_child(_colors.size()))
