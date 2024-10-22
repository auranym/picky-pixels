@tool
extends HBoxContainer

const TOOLTIP = preload("res://addons/picky-pixels/ui/tooltip/tooltip.tscn")

@onready var _indicator = $Indicator


func _ready():
	PickyPixelsManager.get_instance().updated.connect(_update_label)
	_update_label()


func _update_label():
	_indicator.text = "{ramps}/{max_ramps}".format({
		"ramps": PickyPixelsManager.get_instance().project_data.ramps.size(),
		"max_ramps": PickyPixelsManager.MAX_NUM_RAMPS
	})


func _make_custom_tooltip(for_text):
	var tooltip_node = TOOLTIP.instantiate()
	tooltip_node.text = for_text
	return tooltip_node
