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
@onready var cancel = $Buttons/Cancel

var _project_data: PickyPixelsProjectData = null
@export var project_data: PickyPixelsProjectData:
	get: return _project_data
	set(val):
		if not is_node_ready():
			await ready
		_project_data = val
		_import_project_data()


@export var sprite_index: int = -1:
	get: return sprite_index
	set(val):
		if not is_node_ready():
			await ready
		sprite_index = val
		_import_sprite_2d_data()

var selected_tab: int
# Index is the light level tab
var original_textures: Array[Texture2D] = []
var textures: Array[Texture2D] = []
var png_regex: RegEx


func _ready():
	color_ramps_indicator.max_ramps = 255
	png_regex = RegEx.new()
	png_regex.compile(".*\\.png$")
	#_import_project_data()
	#_import_sprite_2d_data()


func _import_project_data():
	if _project_data == null:
		color_ramps_indicator.ramps = 0
		color_palette.colors = [] as Array[Color]
	else:
		color_ramps_indicator.ramps = _project_data.ramps.size()
		color_palette.colors = _project_data.palette
	sprite_index = -1
	_update()


func _import_sprite_2d_data():
	if sprite_index == -1 or _project_data == null:
		textures = [null]
		_set_light_levels(1)
		light_levels_spin_box.set_value_no_signal(1)
	else:
		original_textures = _project_data.sprites[sprite_index].base_textures.duplicate()
		textures = original_textures.duplicate()
		if textures == []:
			textures = [null]
		_set_light_levels(textures.size())
		light_levels_spin_box.set_value_no_signal(textures.size())
	_set_selected_light_level_tab(0)
	_update()


func _set_light_levels(value):
	# Update light level tabs
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
	elif value_diff < 0:
		light_levels_tabs.get_children()
		for i in abs(value_diff):
			light_levels_tabs.remove_child(
				light_levels_tabs.get_children().back()
			)
		# Update selected light level tab if needed
		if selected_tab >= light_levels_tabs.get_child_count():
			selected_tab = light_levels_tabs.get_child_count() - 1
			light_levels_tabs.get_children().back().set_pressed_no_signal(true)
			texture_display.set_texture(textures[selected_tab])
	
	# Update textures array. Done separately from above in case light tabs
	# and textures get out of sync. (Redundancy for safety.)
	textures.resize(value)


func _set_selected_light_level_tab(index):
	light_levels_tabs.get_child(selected_tab).set_pressed_no_signal(false)
	selected_tab = index
	# Update displayed texture
	if index < textures.size():
		texture_display.set_texture(textures[selected_tab])
	else:
		texture_display.set_texture(null)
	light_levels_tabs.get_child(selected_tab).set_pressed_no_signal(true)


func _warn(message: String):
	save.disabled = true
	save.tooltip_text = "Fix issues before saving."
	cancel.disabled = false
	cancel.tooltip_text = "Discard changes."
	warning.text = message
	warning.visible = true


# Called whenever a texture or light level is added or removed.
func _update():
	# First make sure there is a project
	if _project_data == null:
		_warn("Missing project data. This is likely due to a plugin bug. Try restarting your project.")
		return
	
	# Next, make sure there are actually changes worth saving
	if textures == original_textures:
		save.disabled = true
		save.tooltip_text = "No changes to save."
		cancel.disabled = true
		cancel.tooltip_text = "No changes to discard."
		warning.visible = false
		return
	
	var result = _project_data.is_valid_base_textures(textures)
	
	# If there are no issues, then enable the save button
	if result == PickyPixelsProjectData.TexturesStatus.OK:
		save.disabled = false
		save.tooltip_text = ""
		cancel.disabled = false
		cancel.tooltip_text = "Discard changes."
		warning.visible = false
	else:
		match result:
			PickyPixelsProjectData.TexturesStatus.ERR_TEXTURE_NULL:
				_warn("Light levels must all have textures.")
			PickyPixelsProjectData.TexturesStatus.ERR_TEXTURE_SIZE_MISMATCH:
				_warn("Light level textures must all be the same size.")
			PickyPixelsProjectData.TexturesStatus.ERR_UNKNOWN_COLOR:
				_warn("All colors must be from the selected project's color palette.")
			PickyPixelsProjectData.TexturesStatus.ERR_NOT_ENOUGH_RAMPS:
				_warn("Saving will create too many color ramps. Try removing a light layer or making textures more similar.")


func _save():
	_project_data.update_sprite(sprite_index, textures)


func _drop_data(at_position, data):
	print(data.files)


func _on_texture_display_texture_changed(texture):
	textures[selected_tab] = texture
	_update()


func _on_texture_display_load_multiple_textures(texture_files):
	# Assume that texture_files is already a valid Array of file names
	for i in textures.size():
		if i < texture_files.size():
			textures[i] = load(texture_files[i])
		else:
			textures[i] = null
	
	texture_display.set_texture(textures[selected_tab])


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


func _on_cancel_pressed():
	textures = original_textures.duplicate()
	_set_light_levels(textures.size())
	light_levels_spin_box.set_value_no_signal(textures.size())
	_set_selected_light_level_tab(0)
	_update()
