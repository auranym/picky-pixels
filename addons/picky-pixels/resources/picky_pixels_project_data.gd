@tool
## A PickyPixels project contains all information and necessary data
## for rendering a set of sprites, textures, models, etc. within a single
## viewport. The common link between these assets is that they share a color
## palette (and optional effects). Thus, the purpose of a PickyPixels project
## is to set up and easily use a strict color palette.
class_name PickyPixelsProjectData
extends Resource

## Name of the project. Must be unique.
@export var name: String

## Shader that should be applied to the root viewport where all "picky" nodes
## are children. If a picky node is within a tree where its viewport does
## not have the correct shader, there is an error.
@export var root_shader: ShaderMaterial

## TYPE TODO
## PickySprites managed by this project.
@export var sprites: Array[PickySprite2DData]

## Color palette for this project and which sprites use them.
@export var palette: Array[Color]:
	get: return palette
	set(val):
		palette = val
		_color_index_map = {}
		for i in palette.size():
			_color_index_map[color_to_str(palette[i])] = i


## Ramps that should be processed in decoding colors, and which sprites use
## them.
@export var ramps: Array[Array]:
	get: return ramps
	set(val):
		ramps = val
		_ramp_index_map = {}
		for i in ramps.size():
			_ramp_index_map[ramp_to_str(ramps[i] as Array[Color])] = i


# Used for O(1) lookup time.
# Maps a value to its respective index.
var _color_index_map := {}
var _ramp_index_map := {}
var _recycled_g_vals := [] # TODO when implementing "delete sprite"


static func color_to_str(color) -> String:
	if color.a8 != 255:
		return "TRANSPARENT"
	
	return "{r},{g},{b}".format({
		"r": color.r8,
		"g": color.g8,
		"b": color.b8
	})

static func ramp_to_str(ramp) -> String:
	var strings = []
	var all_transparent = true
	for color in ramp:
		var str = color_to_str(color)
		if all_transparent and str != "TRANSPARENT":
			all_transparent = false
		strings.push_back(str)
	if all_transparent:
		return "TRANSPARENT"
	return ";".join(strings)


func has_color(color) -> bool:
	return _color_index_map.has(color_to_str(color))


## Returns true if this project has all colors in input array
func has_colors(colors) -> bool:
	for color in colors:
		if not has_color(color):
			return false
	return true


func has_ramp(ramp) -> bool:
	return _ramp_index_map.has(ramp_to_str(ramp))


## Returns true if this project has all ramps in input array
func has_ramps(ramps) -> bool:
	return num_missing_ramps(ramps) == 0


## Compares this project's ramps with the parameter ramps. For every ramp
## that the project does not have, 1 is added to an accumlator (which starts
## at 0). That is, the return value is 0 if all ramps in parameter are in
## project, and more than 0 if there is one or more missing ramp.
func num_missing_ramps(ramps) -> int:
	return ramps.reduce(
		func(num_missing, ramp): return num_missing + (0 if has_ramp(ramp) else 1),
		0
	)


## Creates a new PickySprite2DData resource based on base_textures. Number of
## light levels is the length of base_textures.
## 
## No validation is done ahead of time. It is assumed that a PickySprite2DData
## can be created without issue.
func create_new_sprite(base_textures: Array[Texture2D], texture_size: Vector2) -> PickySprite2DData:
	var encoded_image = Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	
	# Generate the encoded image
	for x in texture_size.x:
		for y in texture_size.y:
			var ramp = []
			for i in base_textures.size():
				var color = base_textures[i].get_image().get_pixel(x, y)
				ramp.push_back(color)
			var index = _ramp_index_map.get(ramp_to_str(ramp))
			# Add ramp to project if it does not exist
			if index == null:
				index = ramps.size()
				ramps.push_back(ramp)
				_ramp_index_map[ramp_to_str(ramp as Array[Color])] = index
			encoded_image.set_pixel(x, y, Color8(0, index, 0))
	
	# Generate library image by scaling larger dimension to 128
	# and proportionally scaling the other one.
	var library_image = base_textures.back().get_image()
	var x = library_image.get_width()
	var y = library_image.get_height()
	if x > y:
		y = int(floor(128.0 * float(y) / float(x)))
		x = 128
	else:
		x = int(floor(128.0 * float(x) / float(y)))
		y = 128
	library_image.resize(x, y, Image.INTERPOLATE_NEAREST)
	
	var new_sprite_data = PickySprite2DData.new(
		ImageTexture.create_from_image(encoded_image),
		base_textures,
		library_image
	)
	
	sprites.push_back(new_sprite_data)
	return new_sprite_data
