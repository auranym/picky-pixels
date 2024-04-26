class_name PickySprite2DData
extends Resource

## The encoded sprite, set as PickySprite2D's texture property.
@export var image: Image

## Number of light levels encoded in this Resource.
## This is the length of a color ramp.
@export var light_levels: int

## Colors used by a PickySprite2D
@export var colors: Array[Color]

## An array of integer arrays, used to map an encoded
## value to a color ramp. Color ramps detail which color
## to use at a each light level.
@export var ramps: Array[Array]

## Material that should be applied to the PickySprite2D.
## This contains the generated shader.
@export var shader_material: ShaderMaterial

## A 128x128 image used as the display image in the PickyPixels
## Library tab.
@export var library_image: Image

func _init(
	p_image: Image = null,
	p_light_levels: int = 0,
	p_colors: Array[Color] = [],
	p_ramps: Array[Array] = [],
	p_shader_material: ShaderMaterial = null,
	p_library_image: Image = null
):
	image = p_image
	light_levels = p_light_levels
	colors = p_colors
	ramps = p_ramps
	shader_material = p_shader_material
	library_image = p_library_image
