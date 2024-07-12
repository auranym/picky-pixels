class_name PickyPixelsManager
extends Node

signal updated
signal recompile_started
signal recompile_finished

# File system constants
const DIR_PATH = "res://picky_pixels"
const PROJECT_DATA_PATH = DIR_PATH + "/project_data.res"
const TEXTURES_DIR_PATH = DIR_PATH + "/textures"
const SHADERS_DIR_PATH = DIR_PATH + "/shaders"
const PROJECT_SHADER_MATERIAL_PATH = SHADERS_DIR_PATH + "/main.material"

# Used for determining whether texture can be compiled with new
# base_textures or not.
enum TexturesStatus {
	OK = 0,
	ERR_TEXTURE_NULL = 1,
	ERR_TEXTURE_SIZE_MISMATCH = 2,
	ERR_UNKNOWN_COLOR = 3,
	ERR_NOT_ENOUGH_RAMPS = 4
}

static var instance: PickyPixelsManager

var project_data: PickyPixelsProjectData = null:
	get: return project_data

var project_textures: Array[PickyPixelsImageTexture] = []:
	get: return project_textures

## Shader that should be applied to the root viewport where all "picky" nodes
## are children. If a picky node is within a tree where its viewport does
## not have the correct shader, there is an error.
var project_shader_material: ShaderMaterial = null:
	get: return project_shader_material

# Used for O(1) lookup time to see if a texture exists or not.
var _project_textures_set: Dictionary = {}
# Used to space out recompiling across frames
var _recompile_in_progress: bool = false
var _recompiling_text_status: String = ""

# DATA MUTATION SOURCES:
# - Sprite create: library/library
# - Sprite data change: texture_editor/texture_editor
# - Sprite rename: library/sprite_item
# - Sprite delete: library/library
# - Palette change: library/library
# - Recompiling: library/library


static func _static_init():
	instance = PickyPixelsManager.new()


func load_project():
	# First make sure file system exists
	for dir in [DIR_PATH, TEXTURES_DIR_PATH, SHADERS_DIR_PATH]:
		if not DirAccess.dir_exists_absolute(dir):
			DirAccess.make_dir_recursive_absolute(dir)
	
	# Next, load variables used throughout the plugin
	_load_project_file()
	_load_texture_files()
	_load_shader_material_file()
	
	# Then, emit that there has been an update has changed so that the UI
	# can respond.
	updated.emit()


## Recalculates ramps, and recompiles encoded textures and the main shader.
## This is used for loading palettes as well.
func recompile_project(new_palette: Array[Color] = project_data.palette):
	# Make sure there is no current thread
	if _recompile_in_progress:
		print("Recompile already in progress!")
		return
	
	# Init recompilation
	_recompile_in_progress = true
	project_data.palette = new_palette
	project_data.ramps = []
	recompile_started.emit()
	
	# Iterate over all textures to recalculate ramps and textures
	var num_sprites = project_textures.size()
	for i in num_sprites:
		_recompiling_text_status = "Compiling sprite ({i}/{num}).".format({ "i": str(i), "num": num_sprites })
		await get_tree().process_frame

		var texture = project_textures[i]
		if is_valid_base_textures(texture.base_textures) == TexturesStatus.OK:
			compile_texture(texture, texture.base_textures, true)
		else:
			texture.invalid_textures = true
	
	_recompiling_text_status = "Finishing up."
	await get_tree().process_frame
	
	compile_project_shader()
	updated.emit()
	recompile_finished.emit()


## Returns a user-friendly String to display to the user when project is
## being recompiled. If the project is not being recompiled, null is returned.
func get_recompile_text_status():
	if _recompile_in_progress:
		return null
	else:
		return _recompiling_text_status


func is_texture_with_name(name_str: String) -> bool:
	return _project_textures_set.has(TEXTURES_DIR_PATH + "/" + name_str)


## Creates a new PickyPixelsImageTexture resource with the file name provided.
## This function assumes that is_texture_with_name(name_str) returns false.
func create_texture(name_str: String):
	var texture = PickyPixelsImageTexture.new()
	texture.resource_path = TEXTURES_DIR_PATH + "/" + name_str
	ResourceSaver.save(texture)
	_load_texture_files()
	updated.emit()


## Renames the provided PickyPixelsImageTexture resource file name
## and reloads textures.
## This function assumes that is_texture_with_name(new_name_str) returns false.
func rename_texture(resource: PickyPixelsImageTexture, new_name_str: String):
	resource.resource_path = TEXTURES_DIR_PATH + "/" + new_name_str
	ResourceSaver.save(resource)
	_load_texture_files()
	updated.emit()


## Deletes the provided PickyPixelsImageTexture from the project and reloads
## all textures.
func delete_texture(resource: PickyPixelsImageTexture):
	DirAccess.remove_absolute(resource.resource_path)
	_load_texture_files()
	updated.emit()


## Checks whether the passed base_textures are valid with the current project.
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
				if not project_data.has_color(color):
					return TexturesStatus.ERR_UNKNOWN_COLOR
				# If the color is known, add it to the ramp
				ramp.push_back(color)
			# Now add this ramp to the set
			new_ramps[ramp] = true
	
	# Check that there are enough color ramps available
	if project_data.ramps.size() + project_data.num_missing_ramps(new_ramps.keys()) > 255:
		return TexturesStatus.ERR_NOT_ENOUGH_RAMPS
	
	return TexturesStatus.OK


## Updates the encoded texture and base textures for the
## passed PickyPixelsImageTexture resource. Before calling
## this function, you verify base_texture's validity with
## is_valid_base_textures().
func compile_texture(resource: PickyPixelsImageTexture, base_textures: Array[Texture2D], skip_shader_compilation: bool = false):
	var texture_size = base_textures[0].get_size()
	var encoded_image = Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	
	# Generate the encoded image
	for x in texture_size.x:
		for y in texture_size.y:
			var ramp = []
			for i in base_textures.size():
				var color = base_textures[i].get_image().get_pixel(x, y)
				ramp.push_back(color)
			# Skip transparency
			if project_data.is_ramp_transparent(ramp):
				continue
			var ramp_index = project_data.get_ramp_index(ramp)
			# Add ramp to project if it does not exist
			if ramp_index == -1:
				ramp_index = project_data.add_ramp(ramp)
			encoded_image.set_pixel(x, y, Color8(0, ramp_index, 0))
	
	# Update project data
	resource.base_textures = base_textures
	resource.encoded_texture = ImageTexture.create_from_image(encoded_image)
	resource.invalid_textures = false
	if not skip_shader_compilation:
		compile_project_shader()
	
	updated.emit()


func compile_project_shader():
	var code = "
shader_type canvas_item;
render_mode unshaded;

const vec4[] COLORS = { {colors} };
const int[] RAMPS = { {ramps} };
const int[] RAMPS_POINTERS = { {ramps_pointers} };

uniform bool in_editor;

bool is_in_palette(vec4 color) {
	// Ignore transparency
	if (color.a < 1.0) {
		return true;
	}
	
	for (int i = 0; i < COLORS.length(); i++) {
		if (length(color - COLORS[i]) < 0.001) {
			return true;
		}
	}
	return false;
}

void fragment() {
	if (!in_editor && !is_in_palette(COLOR)) {
		if (COLOR.a == 1.0) {
			vec4 c = texture(TEXTURE, UV);
			int ramp = int(255.0 * c.g);
			int ramp_pos = RAMPS_POINTERS[2 * ramp];
			int ramp_size = RAMPS_POINTERS[2 * ramp + 1];
			int light_level = min(int(floor(mix(0.0, float(ramp_size), c.r))), ramp_size-1);
			
			COLOR = COLORS[RAMPS[ramp_pos+light_level]];
		}
	}
}
".trim_prefix("\n").trim_suffix("\n");
	
	# Generate colors array
	# Index 0 is always transparency
	var colors_compiled = ["vec4(0.0,0.0,0.0,0.0)"]
	for i in project_data.palette.size():
		var color = project_data.palette[i]
		colors_compiled.push_back("vec4({r},{g},{b},{a})".format({
			"r": color.r,
			"g": color.g,
			"b": color.b,
			"a": color.a
		}))
	
	# Generate ramps and ramp pointers
	var ramps_pointers_compiled = []
	var ramps_compiled = []
	for i in project_data.ramps.size():
		var ramp = project_data.ramps[i]
		# The 2*n position of ramp pointers is the position of the ramp
		ramps_pointers_compiled.push_back(ramps_compiled.size())
		# The 2*n+1 position is the size of the ramp
		ramps_pointers_compiled.push_back(ramp.size())
		for color in ramp:
			# Like with compile colors above, index 0 is transparency.
			# To adjust for this, we add 1 to the associated index.
			# If the color index map does not have a color string, then it
			# is "TRANSPARENCY" which should be 0 (hence, -1 + 1).
			ramps_compiled.push_back(project_data.get_color_index(color) +1)
	
	# Make sure shader material exists
	if project_shader_material == null:
		project_shader_material = PickyPixelsShaderMaterial.new()
		project_shader_material.shader = Shader.new()
	
	project_shader_material.shader.code = code.format({
		"colors": ",".join(colors_compiled),
		"ramps": ",".join(ramps_compiled),
		"ramps_pointers": ",".join(ramps_pointers_compiled),
	})


func _load_project_file():
	if ResourceLoader.exists(
		PROJECT_DATA_PATH,
		"PickyPixelsProjectData"
	):
		project_data = load(PROJECT_DATA_PATH)
		print("Loaded PickyPixels project (%s)" % PROJECT_DATA_PATH)
	# Try to load from file directly if resource loader isn't ready yet
	elif FileAccess.file_exists(PROJECT_DATA_PATH):
		project_data = ResourceLoader.load(PROJECT_DATA_PATH)
		if project_data == null:
			# Create project if it does not yet exist
			_load_new_project()
			print("Created new PickyPixels project (%s)" % PROJECT_DATA_PATH)
		else:
			print("Loaded PickyPixels project (%s)" % PROJECT_DATA_PATH)
	# Finally, simply create a new project if the file does not exist
	else:
		_load_new_project()
		print("Created new PickyPixels project (%s)" % PROJECT_DATA_PATH)


func _load_new_project():
	project_data = PickyPixelsProjectData.new()
	project_data.resource_path = PROJECT_DATA_PATH
	ResourceSaver.save(project_data)


func _load_texture_files():
	project_textures = []
	_project_textures_set = {}
	
	for file in DirAccess.get_files_at(TEXTURES_DIR_PATH):
		var texture = load(file)
		if texture is PickyPixelsImageTexture:
			project_textures.push_back(texture)
			_project_textures_set[texture.resource_path] = texture


func _load_shader_material_file():
	if ResourceLoader.exists(
		PROJECT_SHADER_MATERIAL_PATH,
		"PickyPixelsShaderMaterial"
	):
		project_shader_material = load(PROJECT_SHADER_MATERIAL_PATH)
	elif FileAccess.file_exists(PROJECT_SHADER_MATERIAL_PATH):
		project_shader_material = load(PROJECT_SHADER_MATERIAL_PATH)
		if project_shader_material == null:
			_load_new_shader_material()
	else:
		_load_new_shader_material()


func _load_new_shader_material():
	project_shader_material = PickyPixelsShaderMaterial.new()
	project_shader_material.shader = Shader.new()
	project_shader_material.shader.code = "shader_type canvas_item;\nrender_mode unshaded;\nuniform bool in_editor;"
	project_shader_material.resource_path = PROJECT_SHADER_MATERIAL_PATH
	ResourceSaver.save(project_shader_material)
