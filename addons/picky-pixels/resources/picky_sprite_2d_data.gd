@tool
class_name PickySprite2DData
extends Resource 

## The encoded image, set as PickySprite2D's texture property.
@export var image: Image

## The textures used to generate the encoded image.
## This is also used for the debug texture displayed in the editor.
@export var base_images: Array[Image]

func _init(
	p_image: Image = null,
	p_base_images: Array[Image] = [],
):
	image = p_image
	base_images = p_base_images
