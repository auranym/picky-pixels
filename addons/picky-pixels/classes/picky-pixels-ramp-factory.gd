class_name PickyPixelsRampFactory
extends Node

static func create(colors: Array[Color], dither_transition_amount) -> Dictionary:
	return {
		"colors": colors,
		"dither_transition_amount": dither_transition_amount
	}
