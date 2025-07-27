@tool
extends VBoxContainer

signal changed(value: int)

const TOOLTIP = preload("res://addons/picky-pixels/ui/tooltip/tooltip.tscn")

@onready var h_slider: HSlider = $HBoxContainer/HSlider

@export var value: int:
	get:
		if not is_node_ready(): await ready
		return int(h_slider.value)
	set(val):
		if not is_node_ready(): await ready
		h_slider.value = float(val)


func _make_custom_tooltip(for_text: String) -> Object:
	var tooltip = TOOLTIP.instantiate()
	tooltip.text = for_text
	return tooltip


func _on_h_slider_value_changed(value: float) -> void:
	var value_int = int(value)
	self.value = value_int
	changed.emit(value_int)
