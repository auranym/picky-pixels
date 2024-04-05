@tool
extends VBoxContainer

const COLOR_PICKER = preload("res://addons/picky-pixels/color_palette/color_picker.tscn")

@onready var _color_picker_container = $ScrollContainer/Config/ColorPickerContainer

func _on_spin_box_value_changed(value):
	var value_diff = value - _color_picker_container.get_child_count()
	
	if value_diff > 0:
		for i in value_diff:
			var new_color_picker = COLOR_PICKER.instantiate()
			new_color_picker.label = str(_color_picker_container.get_child_count() + 1)
			_color_picker_container.add_child(new_color_picker)
	elif value_diff < 0:
		_color_picker_container.get_children()
		for i in abs(value_diff):
			_color_picker_container.remove_child(
				_color_picker_container.get_children().back()
			)
