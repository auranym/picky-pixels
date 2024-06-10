@tool
class_name PickySprite2DData
extends Resource 

## The encoded sprite, set as PickySprite2D's texture property.
@export var texture: Texture2D

## The textures used to generate the encoded image.
## This is also used for the debug texture displayed in the editor.
@export var base_textures: Array[Texture2D]

## A 128x128 image used as the display image in the PickyPixels
## Library tab.
@export var library_image: Image

func _init(
	p_texture: Texture2D = null,
	p_base_textures: Array[Texture2D] = [],
	p_library_image: Image = null
):
	texture = p_texture
	base_textures = p_base_textures
	library_image = p_library_image
