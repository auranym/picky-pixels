@tool
class_name PickyPixelsImageTexture
extends ImageTexture

@export var encoded_image: Image:
	get: return encoded_image
	set(val):
		encoded_image = val
		if encoded_image != null:
			_update_image()

@export var unencoded_image: Image:
	get: return unencoded_image
	set(val):
		unencoded_image = val
		if unencoded_image != null:
			_update_image()

enum ImageType {
	UNSET,
	ENCODED,
	UNENCODED
}

var _image_type: ImageType = ImageType.UNSET


func _update_image():
	if (
		Engine.is_editor_hint() and
		unencoded_image != null and 
		_image_type == ImageType.UNSET
	):
		_image_type = ImageType.UNENCODED
		set_image(unencoded_image)
	elif (
		not Engine.is_editor_hint() and 
		encoded_image != null and 
		_image_type == ImageType.UNSET
	):
		_image_type = ImageType.ENCODED
		set_image(encoded_image)
