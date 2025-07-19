@tool
class_name PickyPixelsManager
extends Node

## Main class used to interface with data within the PickyPixels plugin.
## This is a singleton that allows any part of the UI to update data and
## respond to data updated via the "updated" signal (and other more
## specialized signals).
##
## Types of data are defined within the resources folder and begin with
## "picky_pixels_" and serve as types that can be saved as Resource files.
## This manager class handles where and how these Resource files are
## instanced and saved.
##
## There should be one instance of this node within the scene tree.

# DATA MUTATION SOURCES:
# - Resource create: library/new_item
# - Resource rename: library/texture_item
# - Resrouce data change: texture_editor/texture_editor
# - Resource delete: library/texture_item
# - Palette change: library/library
# - Recompiling: library/library

signal updated
signal recompile_started
signal recompile_finished

# File system constants
const DIR_PATH = "res://picky_pixels"
const PROJECT_DATA_PATH = DIR_PATH + "/project_data.res"
const TEXTURES_DIR_PATH = DIR_PATH + "/textures"
const SHADERS_DIR_PATH = DIR_PATH + "/shaders"
const PROJECT_SHADER_PATH = SHADERS_DIR_PATH + "/main.gdshader"
const PROJECT_SHADER_MATERIAL_PATH = SHADERS_DIR_PATH + "/main.material"
const CANVAS_ITEM_SHADER_PATH = SHADERS_DIR_PATH + "/canvas_item.gdshader"
const CANVAS_ITEM_SHADER_MATERIAL_PATH = SHADERS_DIR_PATH + "/canvas_item.material"
const DEBUG_TEXTURE_PATH = DIR_PATH + "/debug_texture.png"

# Shader-related constants
const DEFAULT_SHADER_CODE = "shader_type canvas_item;\nrender_mode unshaded;\nuniform bool in_editor;"
const MAIN_SHADER_TEMPLATE = preload("res://addons/picky-pixels/shaders/main.gdshader")
const CANVAS_ITEM_SHADER_TEMPLATE = preload("res://addons/picky-pixels/shaders/canvas_item.gdshader")

# Define the max number of ramps.
# Ramps are encoded using G and B color channels
# a as base-256 number to identify them, giving 256^2
# allowed ramps.
# G is the less significant digit, B is more.
# i.e., the 1st ramp is identified as B=0, G=1
# and the 256th ramp is identified as B=1, G=0.
const MAX_NUM_RAMPS = 256 * 256

# Used for determining whether texture can be compiled with new
# base_textures or not.
enum TexturesStatus {
	OK = 0,
	ERR_TEXTURE_NULL = 1,
	ERR_TEXTURE_SIZE_MISMATCH = 2,
	ERR_UNKNOWN_COLOR = 3,
	ERR_NOT_ENOUGH_RAMPS = 4
}

var project_data: PickyPixelsProjectData = null:
	get: return project_data

var project_textures: Array[PickyPixelsImageTexture] = []:
	get: return project_textures

## Shader file attached to project_shader_material
var project_shader: Shader = null:
	get: return project_shader

## Shader material that should be applied to the root viewport where all
## "picky" nodes are children. 
var project_shader_material: ShaderMaterial = null:
	get: return project_shader_material

## Shader material that should be attached to every CanvasItem that displays
## textures created with this plugin.
var canvas_item_shader_material: ShaderMaterial = null:
	get: return canvas_item_shader_material

# Singleton instance
static var _instance: PickyPixelsManager
# Used for O(1) lookup time to see if a texture exists or not.
var _project_textures_set: Dictionary = {}
# Used to space out recompiling across frames
var _recompile_in_progress: bool = false
var _recompiling_text_status: String = ""


static func _static_init():
	if _instance == null:
		_instance = PickyPixelsManager.new()
		_instance.load_project()


func _ready():
	# Unlikely, but if _instance is not yet set, set it to this instance
	if _instance == null:
		_instance = self
		_instance.load_project()
		#print("Used manager instance in scene tree as singleton.")
	# If needed, replace self with _instance within the scene tree.
	elif _instance != self and not _instance.is_inside_tree():
		get_parent().call_deferred("add_child", _instance)
		_instance.call_deferred("set_owner", get_parent())
		_instance.call_deferred("set_name", "PickyPixelsManagerInstance")
		queue_free()
		#print("Replaced instance in scene tree with singleton.")


func _exit_tree():
	# Unset instance if it is being removed from the scene tree
	if _instance == self:
		_instance = null
		#print("Unloaded PickyPixels manager. (Exited scene tree.)")


static func get_instance() -> PickyPixelsManager:
	if _instance == null:
		_instance = PickyPixelsManager.new()
		_instance.load_project()
	return _instance


## Returns true if the passed resource is a PickyPixels resource object that
## is displayed within the library. A valid resource is one of the following:
## - PickyPixelsImageTexture
static func is_valid_resource(resource: Resource) -> bool:
	return resource is PickyPixelsImageTexture


func load_project():
	# First make sure file system exists
	for dir in [DIR_PATH, TEXTURES_DIR_PATH, SHADERS_DIR_PATH]:
		if not DirAccess.dir_exists_absolute(dir):
			DirAccess.make_dir_recursive_absolute(dir)
	
	# Next, load variables used throughout the plugin
	_load_project_file()
	_load_texture_files()
	_load_shader_file()
	_load_shader_material_file()
	_load_canvas_item_shader_material_file()
	
	# Pass along any changed notifications
	project_data.changed.connect(func(): updated.emit())
	
	# Then, emit that there has been an update has changed so that the UI
	# can respond.
	updated.emit()


## Recalculates ramps, and recompiles encoded textures and the main shader.
## This is used for loading palettes as well.
func recompile_project(new_palette: Array[Color] = project_data.palette):
	if not _instance.is_inside_tree():
		push_error("There must be at least once instance of PickyPixelsManager within the scene tree.")
		return
	
	# Make sure there is no current thread
	if _recompile_in_progress:
		push_warning("Recompile already in progress!")
		return
	
	# Init recompilation
	_recompile_in_progress = true
	project_data.palette = new_palette
	project_data.ramps = []
	recompile_started.emit()
	
	# Iterate over all textures to recalculate ramps and textures
	var num_textures = project_textures.size()
	for i in num_textures:
		_recompiling_text_status = "Compiling texture ({i}/{num}).".format({ "i": str(i), "num": num_textures })
		await get_tree().process_frame

		var texture = project_textures[i]
		if is_valid_base_textures(texture.base_textures) == TexturesStatus.OK:
			compile_texture(texture, texture.base_textures, true)
		else:
			texture.invalid_textures = true
	
	_recompiling_text_status = "Finishing up."
	await get_tree().process_frame
	
	ResourceSaver.save(project_data)
	compile_project_shader()
	EditorInterface.get_resource_filesystem().scan()
	_recompile_in_progress = false
	updated.emit()
	recompile_finished.emit()


## Returns a user-friendly String to display to the user when project is
## being recompiled. If the project is not being recompiled, null is returned.
func get_recompile_text_status():
	if not _recompile_in_progress:
		return null
	else:
		return _recompiling_text_status


func is_texture_with_name(name_str: String) -> bool:
	return _project_textures_set.has(name_str)


func has_texture(resource: Resource) -> bool:
	if resource is PickyPixelsImageTexture:
		return project_textures.has(resource)
	else:
		return false


## Creates a new PickyPixelsImageTexture resource with the file name provided.
## This function assumes that is_texture_with_name(name_str) returns false.
func create_texture(name_str: String):
	var texture = PickyPixelsImageTexture.new()
	texture.resource_name = name_str
	texture.take_over_path(TEXTURES_DIR_PATH + "/" + name_str + ".res")
	ResourceSaver.save(texture)
	_load_texture_files()
	updated.emit()


## Renames the provided PickyPixelsImageTexture resource file name
## and reloads textures.
## This function assumes that is_texture_with_name(new_name_str) returns false.
func rename_texture(resource: PickyPixelsImageTexture, new_name_str: String):
	DirAccess.rename_absolute(resource.resource_path, TEXTURES_DIR_PATH + "/" + new_name_str + ".res")
	resource.resource_name = new_name_str
	resource.take_over_path(TEXTURES_DIR_PATH + "/" + new_name_str + ".res")
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
				# Consider anything not opaque as transparent
				if color.a8 != 255:
					color = Color(0.0, 0.0, 0.0, 0.0)
				# Next check if color is in palette
				elif not project_data.has_color(color):
					return TexturesStatus.ERR_UNKNOWN_COLOR
				# If the color is known, add it to the ramp
				ramp.push_back(color)
			# Now add this ramp to the set
			new_ramps[ramp] = true
	
	# Check that there are enough color ramps available
	if (
		project_data.ramps.size()
		+ project_data.num_missing_ramps(new_ramps.keys())
		+ (project_data.palette.size() - project_data.num_unavailable_ramps())
	) > MAX_NUM_RAMPS:
		return TexturesStatus.ERR_NOT_ENOUGH_RAMPS
	
	return TexturesStatus.OK


## Updates the encoded texture and base textures for the
## passed PickyPixelsImageTexture resource. Before calling
## this function, you verify base_texture's validity with
## is_valid_base_textures().
func compile_texture(resource: PickyPixelsImageTexture, base_textures: Array[Texture2D], skip_project_update: bool = false):
	if base_textures.size() == 0:
		return
	
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
			# Encode the ramp using G and B channels.
			var g = ramp_index % 256
			var b = int(floor(ramp_index / 256))
			encoded_image.set_pixel(x, y, Color8(0, g, b))
	
	# Update project data
	resource.base_textures = base_textures
	resource.encoded_texture = ImageTexture.create_from_image(encoded_image)
	resource.invalid_textures = false
	ResourceSaver.save(resource)
	
	if not skip_project_update:
		ResourceSaver.save(project_data)
		compile_project_shader()
		EditorInterface.get_resource_filesystem().scan()
	
	updated.emit()


func compile_project_shader():
	# Set it to default code if there are no ramps
	if project_data.ramps.size() == 0:
		project_shader.code = DEFAULT_SHADER_CODE
		ResourceSaver.save(project_shader)
		return
	
	# Generate colors array
	# Index 0 is always transparency
	var colors_compiled = [Vector4(0.0, 0.0, 0.0, 0.0)]
	for i in project_data.palette.size():
		var color = project_data.palette[i]
		colors_compiled.push_back(Vector4(color.r, color.g, color.b, color.a))
	
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
			# If the color index map does not have a color string, then this
			# function returns -1 (and thus, -1 + 1 = 0).
			ramps_compiled.push_back(project_data.get_color_index(color) +1)
	
	project_shader.code = MAIN_SHADER_TEMPLATE.code.format({
		"colors_size": colors_compiled.size(),
		"ramps_size": ramps_compiled.size(),
		"ramps_pointers_size": ramps_pointers_compiled.size(),
	})
	ResourceSaver.save(project_shader)
	project_shader_material.set_shader_parameter("colors", colors_compiled)
	project_shader_material.set_shader_parameter("ramps", ramps_compiled)
	project_shader_material.set_shader_parameter("ramps_pointers", ramps_pointers_compiled)
	ResourceSaver.save(project_shader_material)
	
	# For debugging purposes
	_compile_debug_texture()


func _compile_debug_texture():
	var debug_texture = Image.create(16, project_data.ramps.size(), false, Image.FORMAT_RGBA8)
	for i in project_data.ramps.size():
		var ramp = project_data.ramps[i]
		for j in ramp.size():
			var color = ramp[j]
			debug_texture.set_pixel(j, i, color)
	debug_texture.save_png(DEBUG_TEXTURE_PATH)


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
	# Check for any changes in the file system...
	EditorInterface.get_resource_filesystem().scan()
	
	project_textures = []
	_project_textures_set = {}
	
	for file in DirAccess.get_files_at(TEXTURES_DIR_PATH):
		var texture = load(TEXTURES_DIR_PATH + "/" + file)
		if texture is PickyPixelsImageTexture:
			project_textures.push_back(texture)
			_project_textures_set[texture.resource_name] = texture


func _load_shader_file():
	if ResourceLoader.exists(
		PROJECT_SHADER_PATH,
		"Shader"
	):
		project_shader = load(PROJECT_SHADER_PATH)
	elif FileAccess.file_exists(PROJECT_SHADER_PATH):
		project_shader = load(PROJECT_SHADER_PATH)
		if project_shader == null:
			_load_new_shader()
	else:
		_load_new_shader()
	

func _load_new_shader():
	project_shader = Shader.new()
	project_shader.code = DEFAULT_SHADER_CODE
	project_shader.resource_path = PROJECT_SHADER_PATH
	ResourceSaver.save(project_shader)


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
	project_shader_material.shader = project_shader
	project_shader_material.resource_path = PROJECT_SHADER_MATERIAL_PATH
	ResourceSaver.save(project_shader_material)


func _load_canvas_item_shader_material_file():
	if ResourceLoader.exists(
		CANVAS_ITEM_SHADER_MATERIAL_PATH,
		"PickyPixelsShaderMaterial"
	):
		canvas_item_shader_material = load(CANVAS_ITEM_SHADER_MATERIAL_PATH)
	elif FileAccess.file_exists(CANVAS_ITEM_SHADER_MATERIAL_PATH):
		canvas_item_shader_material = load(CANVAS_ITEM_SHADER_MATERIAL_PATH)
		if canvas_item_shader_material == null:
			_load_new_canvas_item_shader_material()
	else:
		_load_new_canvas_item_shader_material()


func _load_new_canvas_item_shader_material():
	var shader = Shader.new()
	shader.code = CANVAS_ITEM_SHADER_TEMPLATE.code
	shader.resource_path = CANVAS_ITEM_SHADER_PATH
	ResourceSaver.save(shader)
	
	canvas_item_shader_material = PickyPixelsShaderMaterial.new()
	canvas_item_shader_material.shader = shader
	canvas_item_shader_material.resource_path = CANVAS_ITEM_SHADER_MATERIAL_PATH
	ResourceSaver.save(canvas_item_shader_material)
