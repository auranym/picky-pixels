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
@export var shader_material: ShaderMaterial

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


## Ramps that should be processed in decoding colors.
@export var ramps: Array[Array] = []:
	get: return ramps


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
func create_new_sprite(base_images: Array[Image], texture_size: Vector2) -> PickySprite2DData:
	var encoded_image = Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	
	# Generate the encoded image
	#
	# NOTE:
	# For some reason (likely a compression issue)
	# the colors are occasionally read incorrectly.
	# I think a possible fix would be to do some careful
	# loading in within texture_display such that all
	# image files are loaded in as Images and then
	# converted to Texture2Ds.
	for x in texture_size.x:
		for y in texture_size.y:
			var ramp = []
			for i in base_images.size():
				var color = base_images[i].get_pixel(x, y)
				ramp.push_back(color)
			var index = _ramp_index_map.get(ramp_to_str(ramp))
			# Add ramp to project if it does not exist
			if index == null:
				index = ramps.size()
				ramps.push_back(ramp)
				_ramp_index_map[ramp_to_str(ramp)] = index
			encoded_image.set_pixel(x, y, Color8(0, index, 0))
	
	var new_sprite_data = PickySprite2DData.new(
		encoded_image,
		base_images
	)
	
	# Update project data
	sprites.push_back(new_sprite_data)
	_compile_shader()
	
	return new_sprite_data


func _init():
	shader_material = ShaderMaterial.new()
	shader_material.shader = Shader.new()
	shader_material.shader.code = "shader_type canvas_item;\nrender_mode unshaded;\n"


func _compile_shader():
	var code = "
shader_type canvas_item;
render_mode unshaded;

const vec4[] COLORS = { {colors} };
const int[] RAMPS = { {ramps} };
const int[] RAMPS_POINTERS = { {ramps_pointers} };

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	int ramp = int(255.0 * c.g);
	int ramp_pos = RAMPS_POINTERS[2 * ramp];
	int ramp_size = RAMPS_POINTERS[2 * ramp + 1];
	int light_level = min(int(floor(mix(0.0, float(ramp_size), c.r))), ramp_size-1);
	
	COLOR = COLORS[RAMPS[ramp_pos+light_level]];
}
".trim_prefix("\n").trim_suffix("\n");
	
	# Generate colors array
	# Index 0 is always transparency
	var colors_compiled = ["vec4(0.0,0.0,0.0,0.0)"]
	for i in palette.size():
		var color = palette[i]
		colors_compiled.push_back("vec4({r},{g},{b},{a})".format({
			"r": color.r,
			"g": color.g,
			"b": color.b,
			"a": color.a
		}))
	
	# Generate ramps and ramp pointers
	var ramps_pointers_compiled = []
	var ramps_compiled = []
	for i in ramps.size():
		var ramp = ramps[i]
		# The 2*n position of ramp pointers is the position of the ramp
		ramps_pointers_compiled.push_back(ramps_compiled.size())
		# The 2*n+1 position is the size of the ramp
		ramps_pointers_compiled.push_back(ramp.size())
		for color in ramp:
			# Like with compile colors above, index 0 is transparency.
			# To adjust for this, we add 1 to the associated index.
			# If the color index map does not have a color string, then it
			# is "TRANSPARENCY" which should be 0 (hence, -1 + 1).
			ramps_compiled.push_back(
				_color_index_map.get(color_to_str(color), -1) + 1
			)
	
	# Make sure shader material exists
	if shader_material == null:
		shader_material = ShaderMaterial.new()
		shader_material.shader = Shader.new()
	
	shader_material.shader.code = code.format({
		"colors": ",".join(colors_compiled),
		"ramps": ",".join(ramps_compiled),
		"ramps_pointers": ",".join(ramps_pointers_compiled),
		"num_ramps": ramps.size() # TEST just to see if the compiled shader works
	})
