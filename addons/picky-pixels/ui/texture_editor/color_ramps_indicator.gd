@tool
extends HBoxContainer

const TOOLTIP = preload("res://addons/picky-pixels/ui/tooltip/tooltip.tscn")

@onready var _indicator = $Indicator

var _ramps: int = 0
@export var ramps: int:
	get: return _ramps
	set(val):
		_ramps = val
		if not is_inside_tree():
			await ready
		_update_indicator()

var _max_ramps: int = 255
@export var max_ramps: int:
	get: return _max_ramps
	set(val):
		_max_ramps = val
		if not is_inside_tree():
			await ready
		_update_indicator()

func _update_indicator():
	_indicator.text = "{ramps}/{max_ramps}".format({
		"ramps": _ramps,
		"max_ramps": _max_ramps
	});

func _make_custom_tooltip(for_text):
	var tooltip_node = TOOLTIP.instantiate()
	tooltip_node.text = for_text
	return tooltip_node
