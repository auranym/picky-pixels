@tool
## A PickyPixels project contains all information and necessary data
## for rendering a set of sprites, textures, models, etc. within a single
## viewport. The common link between these assets is that they share a color
## palette (and optional effects). Thus, the purpose of a PickyPixels project
## is to set up and easily use a strict color palette.
class_name PickyPixelsProjectData
extends Resource

signal sprite_deleted(index: int)

enum TexturesStatus {
	OK = 0,
	ERR_TEXTURE_NULL = 1,
	ERR_TEXTURE_SIZE_MISMATCH = 2,
	ERR_UNKNOWN_COLOR = 3,
	ERR_NOT_ENOUGH_RAMPS = 4
}

const TRANSPARENT_ID = "TRANSPARENT"
const TRANSPARENT_RAMP = [Color(0.0, 0.0, 0.0, 0.0)]

## Name of the project. Must be unique.
@export var name: String:
	get: return name
	set(val):
		name = val
		emit_changed()


## Shader that should be applied to the root viewport where all "picky" nodes
## are children. If a picky node is within a tree where its viewport does
## not have the correct shader, there is an error.
@export var shader_material: ShaderMaterial:
	get: return shader_material
	set(val):
		shader_material = val
		emit_changed()


## PickySprites managed by this project.
@export var sprites: Array[PickySprite2DData]:
	get: return sprites
	set(val):
		sprites = val
		emit_changed()


## Color palette for this project and which sprites use them.
@export var palette: Array[Color]:
	get: return palette
	set(val):
		palette = val
		_color_index_map = {}
		for i in palette.size():
			_color_index_map[color_to_str(palette[i])] = i
		emit_changed()


## Ramps that should be processed in decoding colors.
# Changed does not need to be emitted because this
# is always updated when sprites is updated.
@export var ramps: Array[Array] = []:
	get: return ramps
	set(val):
		ramps = val
		_ramp_index_map = {}
		for i in ramps.size():
			_ramp_index_map[ramp_to_str(ramps[i])] = i
		emit_changed()

# Which sprites (given by their indices in sprites array) use the ramp
# at each index. That is, the index in this array indicates a ramp's
# index in the ramp array, and the values of this array is an array
# of sprites (given by their indices) that use the respective ramp.
#@export var ramps_usage := []:
	#get: return ramps_usage
	#set(val):
		#ramps_usage = val
		#for i in ramps_usage.size():
			#var usage = ramps_usage[i]
			#if usage == null or usage.size() == 0:
				#_recycled_ramp_indices.push_back(i)
		#emit_changed()


# Used for O(1) lookup time.
# Maps a value to its respective index.
var _color_index_map := {}
var _ramp_index_map := {}
#var _recycled_ramp_indices := [] # <- this is a hard problem... TODO!!


static func color_to_str(color) -> String:
	if color.a8 != 255:
		return TRANSPARENT_ID
	
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
		if all_transparent and str != TRANSPARENT_ID:
			all_transparent = false
		strings.push_back(str)
	if all_transparent:
		return TRANSPARENT_ID
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


## Creates a new PickySprite2DData resource and adds it to this project.
## The index of the new sprite is returned.
func create_sprite():
	var index = sprites.size()
	sprites.push_back(PickySprite2DData.new("New Sprite"))
	emit_changed()


func delete_sprite(index: int):
	if index < 0 or index >= sprites.size():
		push_error("Error: Attempted to remove PickySprite2DData at invalid index: " + str(index))
		return
	
	# Remove any ramps that are no longer used
	#for i in ramps_usage.size():
		## If the usage is null, then it is unused.
		#if ramps_usage[i] == null: continue
		#
		## First, find where "index" is within a ramp's usage array.
		#var sprite_usage_index = ramps_usage[i].find(index)
		#if sprite_usage_index != -1:
			## If the sprite index is found within the usage array, remove it
			#ramps_usage[i].remove_at(sprite_usage_index)
			#
			## If the ramp is no longer used, remove it entirely, and indicate that
			## the ramp index should be used for any new ramps.
			#if ramps_usage[i].size() == 0:
				#_ramp_index_map.erase(ramp_to_str(ramps[i]))
				#ramps[i] = null
				#ramps_usage[i] = null
				#_recycled_ramp_indices.push_back(i)
	
	sprites.pop_at(index)
	emit_changed()
	sprite_deleted.emit(index)


func is_valid_base_textures(base_textures: Array[Texture2D]) -> TexturesStatus:
	var texture_size: Vector2
	
	# First determine whether all light levels have a texture
	# and make sure all textures have the same dimensions.
	for i in base_textures.size():
		var texture = base_textures[i]
		if texture == null:
			return TexturesStatus.ERR_TEXTURE_NULL
		# If not null, cast as a Texture2D to make autocomplete nicer
		texture = texture as Texture2D
		if i == 0:
			texture_size = texture.get_size()
		elif texture.get_size() != texture_size:
			return TexturesStatus.ERR_TEXTURE_SIZE_MISMATCH 
	
	var new_ramps = {}
	# For every pixel, iterate over light levels find which ramps and colors
	# are used 
	for x in texture_size.x:
		for y in texture_size.y:
			var ramp = []
			for i in base_textures.size():
				var color = base_textures[i].get_image().get_pixel(x, y)
				# Do not consider anything translucent
				if color.a8 != 255: continue
				# Next check if color is in palette
				if not has_color(color):
					return TexturesStatus.ERR_UNKNOWN_COLOR
				# If the color is known, add it to the ramp
				ramp.push_back(color)
			# Now add this ramp to the set
			new_ramps[ramp] = true
	
	# Check that there are enough color ramps available
	if ramps.size() + num_missing_ramps(new_ramps.keys()) > 255:
		return TexturesStatus.ERR_NOT_ENOUGH_RAMPS
	
	return TexturesStatus.OK


## Updates the encoded image and base textures for the
## PickySprite2DData resource at the specified index. Before calling
## this function, you verify base_texture's validity with
## is_valid_base_textures().
func update_sprite(index: int, base_textures: Array[Texture2D]):
	var texture_size = base_textures[0].get_size()
	var encoded_image = Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	
	# Generate the encoded image
	#
	# NOTE:
	# For some reason (likely a compression issue)
	# the colors are occasionally read incorrectly.
	# I don't know of a fix within the plugin, but it's
	# resolved when the image is re-imported. So just
	# be sure to document this!
	for x in texture_size.x:
		for y in texture_size.y:
			var ramp = []
			for i in base_textures.size():
				var color = base_textures[i].get_image().get_pixel(x, y)
				ramp.push_back(color)
			var ramp_str = ramp_to_str(ramp)
			var ramp_index = _ramp_index_map.get(ramp_str)
			# Add ramp to project if it does not exist
			if ramp_index == null:
				# Use any indices that should be recycled, if available
				#if _recycled_ramp_indices.size() > 0:
					#ramp_index = _recycled_ramp_indices.pop_front()
				#else:
					#ramp_index = ramps.size()
					#ramps.push_back(null)
					#ramps_usage.push_back(null)
				ramp_index = ramps.size()
				# Once we know the index, assign the new value
				if ramp_str == TRANSPARENT_ID:
					ramps.push_back(TRANSPARENT_RAMP)
				else:
					ramps.push_back(ramp)
				_ramp_index_map[ramp_str] = ramp_index
				#ramps_usage[ramp_index] = index
			encoded_image.set_pixel(x, y, Color8(0, ramp_index, 0))
	
	# Update project data
	sprites[index].base_textures = base_textures
	sprites[index].texture = ImageTexture.create_from_image(encoded_image)
	compile_shader()
	emit_changed()


func compile_shader():
	var code = "
shader_type canvas_item;
render_mode unshaded;

const vec4[] COLORS = { {colors} };
const int[] RAMPS = { {ramps} };
const int[] RAMPS_POINTERS = { {ramps_pointers} };

uniform bool in_editor;

void fragment() {
	if (!in_editor) {
		vec4 c = texture(TEXTURE, UV);
		int ramp = int(255.0 * c.g);
		int ramp_pos = RAMPS_POINTERS[2 * ramp];
		int ramp_size = RAMPS_POINTERS[2 * ramp + 1];
		int light_level = min(int(floor(mix(0.0, float(ramp_size), c.r))), ramp_size-1);
		
		COLOR = COLORS[RAMPS[ramp_pos+light_level]];
	}
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
		shader_material = PickyPixelsShaderMaterial.new()
		shader_material.shader = Shader.new()
	
	shader_material.shader.code = code.format({
		"colors": ",".join(colors_compiled),
		"ramps": ",".join(ramps_compiled),
		"ramps_pointers": ",".join(ramps_pointers_compiled),
		"num_ramps": ramps.size() # TEST just to see if the compiled shader works
	})


func _init():
	shader_material = PickyPixelsShaderMaterial.new()
	shader_material.shader = Shader.new()
	shader_material.shader.code = "shader_type canvas_item;\nrender_mode unshaded;\nuniform bool in_editor;"
