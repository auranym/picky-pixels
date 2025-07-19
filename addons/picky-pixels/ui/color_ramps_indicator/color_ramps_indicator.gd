@tool
extends HBoxContainer

const TOOLTIP = preload("res://addons/picky-pixels/ui/tooltip/tooltip.tscn")
const TOOLTIP_TEXT = """
Color ramps used: {ramps} out of {max_ramps}.

Color behavior for each pixel at each light level is stored by generating and assigning a color ramp to that pixel. This color ramp encodes the behavior of that pixel for each light level. Since this data is stored in a pixel's color value, there are a limited number of possible values that the color could be, so there is a cap on the number of color ramps.

If you are running out of color ramps, try recompiling, or consider using less colors in your palette.
"""

@onready var _indicator = $Indicator


func _ready():
	PickyPixelsManager.get_instance().updated.connect(_update_label)
	_update_label()


func _update_label():
	var ramps = PickyPixelsManager.get_instance().project_data.ramps.size()
	var max_ramps = PickyPixelsManager.MAX_NUM_RAMPS
	_indicator.text = "%.2f%%" % (float(ramps) / float(max_ramps))
	tooltip_text = TOOLTIP_TEXT.strip_edges().format({
		"ramps": ramps,
		"max_ramps": max_ramps
	})


func _make_custom_tooltip(for_text):
	var tooltip_node = TOOLTIP.instantiate()
	tooltip_node.text = for_text
	return tooltip_node
