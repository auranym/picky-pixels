@tool
extends VBoxContainer

const LIGHT_LEVEL_TAB = preload("res://addons/picky-pixels/texture_editor/light_level_tab.tscn")
@onready var color_ramps_indicator = $Main/Config/ColorRampsIndicator/Indicator
@onready var light_levels_tabs = $Main/LightLevelData/ScrollContainer/LightLevelsTabs
@onready var light_levels_spin_box = $Main/Config/LightLevelsConfig/SpinBox
@onready var texture_display = $Main/LightLevelData/TextureDisplay
@onready var color_palette = $Main/Config/ColorPalette
@onready var warning = $Warning
@onready var save = $Buttons/Save
var selected_tab: int
# Index is the light level tab
var textures: Array[Texture2D] = []
# Maps an index (0-255) to a color ramp. A color ramp is an array of colors
# Where the color at an index is the color for that respective light level.
# For example, the color at index 2 is the color used at light level 2.
var color_ramps: Dictionary
# Keep track of all colors used. This is only used for displaying color palette.
var colors: Dictionary
# This is a 2D array that maps a pixel's XY coordinates to
# an index/key in the color_ramp Dictionary.
var color_map: Array[Array]


func _ready():
	color_ramps_indicator.text = "0/255"
	_on_light_levels_value_changed(2)
	_on_light_level_tab_button_pressed(0)
	_on_light_level_tab_toggled(0)
	color_palette.colors = [] as Array[Color]


func _warn(message: String):
	save.disabled = true
	warning.text = message
	warning.visible = true
	color_palette.colors = [] as Array[Color]


# Called whenever a texture or light level is added or removed.
func _update():
	var texture_size: Vector2
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
	
	# Next, reinit color-encoding variables and attempt to make a color map
	color_ramps = {}
	colors = {}
	color_map = []
	# For every pixel, iterate over light levels to generate a color ramp.
	# A color ramp is an array of colors, 
	for x in texture_size.x:
		color_map.append([])
		for y in texture_size.y:
			var ramp = []
			for i in textures.size():
				var color = textures[i].get_image().get_pixel(x, y)
				if color.a == 1.0:
					ramp.append(color)
					colors[color] = true
				# For anything translucent, treat it as transparent
				else:
					ramp.append(Color(0.0, 0.0, 0.0, 0.0))
			# Keep track of color ramps
			color_ramps[ramp] = true
			# Associate color ramp with pixel
			color_map[x].append(ramp)
	
	# This is necessary because of color palette's strong typing...
	var colors_array: Array[Color] = []
	for c in colors.keys():
		colors_array.append(c)
	color_palette.colors = colors_array
	var num_color_ramps = color_ramps.keys().size()
	color_ramps_indicator.text = "%s/255" % num_color_ramps
	
	# Finally, check that there are not too many color ramps
	if num_color_ramps > 255:
		_warn("Too many color ramps. Try removing a light layer or making textures more similar.")
		return
	
	# If there are no issues, then enable the save button
	save.disabled = false
	warning.visible = false


func _save():
	# Iterate over each pixel in color_map and generate
	# color ramp atlas. Assign the G value of the encoded texture
	# to the index of the color ramp in the atlas.
	# Then, write a bespoke shader using the atlas.
	var texture_size = Vector2(color_map.size(), color_map[0].size())
	var encoded_image = Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	var atlas = []
	var atlas_set = {} # used to map ramps to indices in O(1) time.
	for x in texture_size.x:
		for y in texture_size.y:
			var ramp = color_map[x][y]
			var index = atlas_set.get(ramp)
			# If ramp not in atlas, add it
			if index == null:
				atlas.append(ramp)
				index = atlas.size()-1
				atlas_set[ramp] = index
			encoded_image.set_pixel(x, y, Color8(0, index, 0))
	
	var err = encoded_image.save_png("res://test/compiled_texture.png")
	if err:
		print(err)
	else:
		print("Encoded successfully!")
	
	# Shader TODO
	var shader_code = _get_shader_code(atlas);
	var file = FileAccess.open("res://test/compiled_shader.gdshader", FileAccess.WRITE)
	file.store_string(shader_code);


func _get_shader_code(atlas) -> String:
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
	var ramps = []
	var ramp_template = "Ramp({ {ramp} })"
	for ramp in atlas:
		# Convert ramp to integer array, and add to colors_to_indices as needed
		var ramp_arr = []
		for color in ramp:
			var index = colors_to_indices.get(color);
			if index == null:
				index = colors_to_indices.size()
				colors_to_indices[color] = index
			ramp_arr.append(index)
		# Now add strings
		ramps.append(ramp_template.format({"ramp": ", ".join(ramp_arr)}))
	
	# Generate colors array
	var colors = []
	colors.resize(colors_to_indices.size())
	for key in colors_to_indices.keys():
		colors[colors_to_indices[key]] = "vec4({r}, {g}, {b}, {a})".format({
			"r": key.r,
			"g": key.g,
			"b": key.b,
			"a": key.a
		})
	
	return code.format({
		"light_levels": light_levels_spin_box.value,
		"colors": ", ".join(colors),
		"ramps": ", ".join(ramps)
	});


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
	
	_update()


func _on_save_pressed():
	_save()
