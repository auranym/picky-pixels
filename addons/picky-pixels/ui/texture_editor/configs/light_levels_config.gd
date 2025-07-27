@tool
extends HBoxContainer

signal changed(value: int)

const TOOLTIP = preload("res://addons/picky-pixels/ui/tooltip/tooltip.tscn")

@onready var spin_box: SpinBox = $SpinBox

@export var value: int:
	get:
		if not is_node_ready(): await ready
		return spin_box.value
	set(val):
		if not is_node_ready(): await ready
		spin_box.value = val


func _make_custom_tooltip(for_text: String) -> Object:
	var tooltip = TOOLTIP.instantiate()
	tooltip.text = for_text
	return tooltip


func _on_spin_box_value_changed(value: float) -> void:
	self.value = value
	changed.emit(value)
