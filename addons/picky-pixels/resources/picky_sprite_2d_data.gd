@tool
class_name PickySprite2DData
extends Resource 

@export var name: String:
	get: return name
	set(val):
		name = val
		emit_changed()

## The encoded image, set as PickySprite2D's texture property.
@export var texture: Texture2D:
	get: return texture
	set(val):
		texture = val
		emit_changed()

## The textures used to generate the encoded image.
## This is also used for the debug texture displayed in the editor.
@export var base_textures: Array[Texture2D]:
	get: return base_textures
	set(val):
		base_textures = val
		emit_changed()

## Indicates whether the sprite has any issues with its base_textures.
## This can only set to true after the project recompiles.
@export var invalid_textures: bool:
	get: return invalid_textures
	set(val):
		invalid_textures = val
		emit_changed()

func _init(
	p_name: String = "",
	p_texture: Texture2D = null,
	p_base_textures: Array[Texture2D] = [null],
	p_invalid_textures: bool = false
):
	name = p_name
	texture = p_texture
	base_textures = p_base_textures
	invalid_textures = p_invalid_textures
