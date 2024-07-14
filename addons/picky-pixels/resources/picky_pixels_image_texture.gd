@tool
class_name PickyPixelsImageTexture
extends ImageTexture

@export var encoded_texture: Texture2D:
	get: return encoded_texture
	set(val):
		encoded_texture = val
		if encoded_texture != null:
			_update_image()

@export var base_textures: Array[Texture2D]:
	get: return base_textures
	set(val):
		base_textures = val
		if base_textures != null and base_textures.size() > 0:
			_update_image()

@export var invalid_textures: bool = false

enum ImageType {
	UNSET,
	ENCODED,
	UNENCODED
}

var _image_type: ImageType = ImageType.UNSET

func _update_image():
	if (
		Engine.is_editor_hint() and
		base_textures != null and 
		base_textures.size() > 0 and
		_image_type != ImageType.ENCODED
	):
		_image_type = ImageType.UNENCODED
		set_image(base_textures.back().get_image())
	elif (
		not Engine.is_editor_hint() and 
		encoded_texture != null and 
		_image_type != ImageType.UNENCODED
	):
		_image_type = ImageType.ENCODED
		set_image(encoded_texture.get_image())
