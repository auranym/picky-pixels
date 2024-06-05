@tool
extends TextureRect

var _data: PickySprite2DData
@export var data: PickySprite2DData:
	get: return _data
	set(d):
		if not is_inside_tree():
			await ready
		_data = d
		
		if _data == null:
			texture = null
		else:
			texture = ImageTexture.create_from_image(_data.library_image)
