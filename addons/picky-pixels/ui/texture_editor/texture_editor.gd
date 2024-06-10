@tool
extends VBoxContainer

const LIGHT_LEVEL_TAB = preload("res://addons/picky-pixels/ui/texture_editor/light_level_tab.tscn")
@onready var color_ramps_indicator = $Main/Config/ColorRampsIndicator
@onready var light_levels_tabs = $Main/LightLevelData/ScrollContainer/LightLevelsTabs
@onready var light_levels_spin_box = $Main/Config/LightLevelsConfig/SpinBox
@onready var texture_display = $Main/LightLevelData/TextureDisplay
@onready var color_palette = $Main/Config/ColorPalette
@onready var warning = $Warning
@onready var save = $Buttons/Save

var _project_data: PickyPixelsProjectData = null
@export var project_data: PickyPixelsProjectData:
	get: return _project_data
	set(d):
		if not is_inside_tree():
			await ready
		_project_data = d
		_import_project_data()

var _sprite_2d_data: PickySprite2DData = null
@export var sprite_2d_data: PickySprite2DData:
	get: return _sprite_2d_data
	set(d):
		if not is_inside_tree():
			await ready
		_sprite_2d_data = d
		_import_sprite_2d_data()

var selected_tab: int
# Index is the light level tab
var textures: Array[Texture2D] = []
var texture_size: Vector2
var colors_set = {}
var ramps_set = {}

func _ready():
	color_ramps_indicator.max_ramps = 255
	_import_project_data()
	_import_sprite_2d_data()


func _import_project_data():
	if _project_data == null:
		color_ramps_indicator.ramps = 0
		color_palette.colors = [] as Array[Color]
	else:
		color_ramps_indicator.ramps = _project_data.ramps.size()
		color_palette.colors = _project_data.palette
	_update()


func _import_sprite_2d_data():
	if _sprite_2d_data == null:
		textures = [] as Array[Texture2D]
		_set_light_levels(1)
	else:
		textures = _sprite_2d_data.base_textures
		_set_light_levels(_sprite_2d_data.light_levels)
	_set_selected_light_level_tab(0)
	_update()


func _set_light_levels(value):
	var value_diff = value - light_levels_tabs.get_child_count()
	
	if value_diff > 0:
		for i in value_diff:
			var new_tab = LIGHT_LEVEL_TAB.instantiate()
			var index = light_levels_tabs.get_child_count()
			new_tab.text = str(index)
			new_tab.tooltip_text = "View light level %s texture" % str(index)
			new_tab.button_down.connect(
				func(): _on_light_level_tab_button_pressed(index)
			)
			new_tab.toggled.connect(
				func(toggled_on): _on_light_level_tab_toggled(index)
			)
			light_levels_tabs.add_child(new_tab)
			# Update array so it is the correct length
			textures.append(null)
	elif value_diff < 0:
		light_levels_tabs.get_children()
		for i in abs(value_diff):
			light_levels_tabs.remove_child(
				light_levels_tabs.get_children().back()
			)
			# Update array so it is the correct length
			textures.pop_back()
		# Update selected light level tab if needed
		if selected_tab >= light_levels_tabs.get_child_count():
			selected_tab = light_levels_tabs.get_child_count() - 1
			light_levels_tabs.get_children().back().set_pressed_no_signal(true)
			texture_display.set_texture(textures[selected_tab])


func _set_selected_light_level_tab(index):
	light_levels_tabs.get_child(selected_tab).set_pressed_no_signal(false)
	selected_tab = index
	# Update displayed texture
	texture_display.set_texture(textures[selected_tab])
	light_levels_tabs.get_child(selected_tab).set_pressed_no_signal(true)


func _warn(message: String):
	save.disabled = true
	warning.text = message
	warning.visible = true


# Called whenever a texture or light level is added or removed.
func _update():
	# First make sure there is a project
	if _project_data == null:
		_warn("Missing project data. This is likely due to a plugin bug. Try restarting your project.")
		return
	
	# First determine whether all light levels have a texture
	# and make sure all textures have the same dimensions.
	for i in textures.size():
		var texture = textures[i]
		if texture == null:
			_warn("Light level " + str(i) + " is missing a texture")
			return
		# If not null, cast as a Texture2D to make autocomplete nicer
		texture = texture as Texture2D
		if i == 0:
			texture_size = texture.get_size()
		elif texture.get_size() != texture_size:
			_warn("Light level " + str(i) + " texture has dimensions different from previous light levels")
			return 
	
	# Reset variables
	colors_set = {}
	ramps_set = {}
	# For every pixel, iterate over light levels find which ramps and colors
	# are used 
	for x in texture_size.x:
		for y in texture_size.y:
			var ramp = []
			for i in textures.size():
				var color = textures[i].get_image().get_pixel(x, y)
				# Do not consider anything translucent
				if color.a8 != 255: continue
				colors_set[color] = true
				ramp.push_back(color)
			ramps_set[ramp] = true
	
	# Check that only colors in the project palette are used
	if not _project_data.has_colors(colors_set.keys()):
		_warn("All colors must be from the selected project's color palette.")
		return
	
	# Check that there are enough color ramps available
	if _project_data.ramps.size() + _project_data.num_missing_ramps(ramps_set.keys()) > 255:
		_warn("Saving will create too many color ramps. Try removing a light layer or making textures more similar.")
		return
	
	# If there are no issues, then enable the save button
	save.disabled = false
	warning.visible = false


func _save():
	print("pressed save")
	
	var sprite_data = _project_data.create_new_sprite(textures, texture_size)
	
	var err = ResourceSaver.save(sprite_data, "res://test/generated_sprite.res")
	if err:
		print(err)
	else:
		print("Generated sprite successfully!")
	
	err = ResourceSaver.save(_project_data, "res://test/generated_project.res")
	if err:
		print(err)
	else:
		print("Generated project successfully!")
	
	
	# Iterate over each pixel in color_map and generate
	# color ramps. Assign the G value of the encoded texture
	# to the index of the color ramp in the ramps array.
	#var texture_size = Vector2(color_map.size(), color_map[0].size())
	#var encoded_image = Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	#var ramps = []
	#var ramps_set = {} # used to map ramps to indices in O(1) time.
	#for x in texture_size.x:
		#for y in texture_size.y:
			#var ramp = color_map[x][y]
			#var index = ramps_set.get(ramp)
			## If ramp not in atlas, add it
			#if index == null:
				#ramps.append(ramp)
				#index = ramps.size()-1
				#ramps_set[ramp] = index
			#encoded_image.set_pixel(x, y, Color8(0, index, 0))
	#
	#var data = _get_picky_sprite_2d_data(encoded_image, ramps)
	#var err = ResourceSaver.save(data, "res://test/generated_resource.res")
	#if err:
		#print(err)
	#else:
		#print("Generated resource successfully!")
	
	#var err = encoded_image.save_png("res://test/compiled_texture.png")
	#if err:
		#print(err)
	#else:
		#print("Encoded successfully!")
	
	# Shader TODO
	#var shader_code = _get_shader_code(ramps);
	#var file = FileAccess.open("res://test/compiled_shader.gdshader", FileAccess.WRITE)
	#file.store_string(shader_code);


#func _get_picky_sprite_2d_data(image: Image, ramps) -> PickySprite2DData:
	## Calculate ramps
	#var colors_to_indices = {};
	#var ramps_compressed: Array[Array] = []
	#for ramp in ramps:
		## Convert ramp to integer array, and add to colors_to_indices as needed
		#var ramp_arr = []
		#for color in ramp:
			#var index = colors_to_indices.get(color);
			#if index == null:
				#index = colors_to_indices.size()
				#colors_to_indices[color] = index
			#ramp_arr.append(index)
		## Now add strings
		#ramps_compressed.append(ramp_arr)
	#
	## Generate colors array
	#var colors_array: Array[Color] = []
	#colors_array.resize(colors_to_indices.size())
	#for color in colors_to_indices.keys():
		#colors_array[colors_to_indices[color]] = color
	#
	## Generate library image by scaling larger dimension to 128
	## and proportionally scaling the other one.
	#var library_image = textures[textures.size()-1].get_image()
	#var x = library_image.get_width()
	#var y = library_image.get_height()
	#if x > y:
		#y = int(floor(128.0 * float(y) / float(x)))
		#x = 128
	#else:
		#x = int(floor(128.0 * float(x) / float(y)))
		#y = 128
	#print(x)
	#print(y)
	#library_image.resize(x, y, Image.INTERPOLATE_NEAREST)
	#
	## Assign values
	#var light_levels = light_levels_spin_box.value
	#return PickySprite2DData.new(
		#image,
		#light_levels,
		#colors_array,
		#ramps_compressed,
		#_get_shader_material(light_levels, colors_array, ramps_compressed),
		#library_image
	#)


func _get_shader_material(light_levels: int, colors: Array, ramps: Array) -> ShaderMaterial:
	var code = "
shader_type canvas_item;
render_mode unshaded;

struct Ramp {
	int[{light_levels}] arr;
};

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

const int LIGHT_LEVELS = {light_levels};
const vec4[] COLORS = { {colors} };
const Ramp[] RAMPS = { {ramps} };

void fragment() {
	vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);
	int light_level = int(round(c.r * float(LIGHT_LEVELS-1)));
	int ramp = int(round(c.g * 255.0));
	
	if (c.a > 0.95) {
		COLOR = COLORS[RAMPS[ramp].arr[light_level]];
	}
	else {
		COLOR = vec4(0.0);
	}
}
".trim_prefix("\n").trim_suffix("\n");
	
	var colors_to_indices = {};
	var ramps_compiled = []
	for ramp in ramps:
		ramps_compiled.append("Ramp({ {ramp} })".format({"ramp": ", ".join(ramp)}))
	
	# Generate colors array
	var colors_compiled = []
	for color in colors:
		colors_compiled.append("vec4({r}, {g}, {b}, {a})".format({
			"r": color.r,
			"g": color.g,
			"b": color.b,
			"a": color.a
		}))
	
	var shader = Shader.new()
	shader.code = code.format({
		"light_levels": light_levels,
		"colors": ", ".join(colors_compiled),
		"ramps": ", ".join(ramps_compiled)
	});
	
	var shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	return shader_material


func _on_texture_display_texture_changed(texture):
	textures[selected_tab] = texture
	_update()


func _on_light_level_tab_button_pressed(index: int):
	# Unselect previous tab
	if selected_tab != index:
		# Set pressed with no signal since the signal is listened to in
		# _on_light_level_tab_toggled
		light_levels_tabs.get_child(selected_tab).set_pressed_no_signal(false)
		selected_tab = index
		
		# Update displayed texture
		texture_display.set_texture(textures[selected_tab])


func _on_light_level_tab_toggled(index: int):
	# Prevent unselecting current tab
	if selected_tab == index:
		light_levels_tabs.get_child(selected_tab).button_pressed = true


func _on_light_levels_value_changed(value):
	_set_light_levels(value)
	_update()


func _on_save_pressed():
	_save()
