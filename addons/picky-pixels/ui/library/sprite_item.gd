@tool
extends TextureRect

var _data: PickySprite2DData
@export var data: PickySprite2DData:
	get: return _data
	set(d):
		_data = d
		if not is_inside_tree():
			await ready
		_generate_texture()


func _ready():
	_generate_texture()


func _generate_texture():
	if _data == null or _data.base_images == null or _data.base_images.size() == 0:
		texture = null
	else:
		# Generate library image by scaling larger dimension to 128
		# and proportionally scaling the other one.
		var library_image = _data.base_images.back()
		var x = library_image.get_width()
		var y = library_image.get_height()
		if x > y:
			y = int(floor(128.0 * float(y) / float(x)))
			x = 128
		else:
			x = int(floor(128.0 * float(x) / float(y)))
			y = 128
		library_image.resize(x, y, Image.INTERPOLATE_NEAREST)
		texture = library_image
