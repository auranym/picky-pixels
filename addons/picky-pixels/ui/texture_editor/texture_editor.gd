@tool
extends VBoxContainer

signal made_changes(texture: PickyPixelsImageTexture)
signal no_changes(texture: PickyPixelsImageTexture)

const LIGHT_LEVEL_TAB = preload("res://addons/picky-pixels/ui/texture_editor/light_level_tab.tscn")
@onready var color_ramps_indicator = $Main/Config/ColorRampsIndicator
@onready var light_levels_tabs = $Main/LightLevelData/ScrollContainer/LightLevelsTabs
@onready var light_levels_config: HBoxContainer = $Main/Config/VBoxContainer/LightLevelsConfig
@onready var texture_display = $Main/LightLevelData/TextureDisplay
@onready var warning = $VBoxContainer/Warning
@onready var save = $VBoxContainer/Buttons/Save
@onready var cancel = $VBoxContainer/Buttons/Cancel
@onready var effects_container: VBoxContainer = $Main/Config/VBoxContainer/EffectsContainer
@onready var show_hide_effects: Button = $Main/Config/VBoxContainer/ShowHideEffects
@onready var dithered_transition_config: VBoxContainer = $Main/Config/VBoxContainer/EffectsContainer/DitheredTransitionConfig

@export var texture: PickyPixelsImageTexture:
	get: return texture
	set(val):
		if not is_node_ready():
			await ready
		texture = val
		textures = texture.base_textures.duplicate()
		if textures.size() == 0:
			textures = [null]
		original_textures = textures.duplicate()
		
		dithered_transition_config.value = texture.dither_transition_amount
		_set_light_levels(textures.size())
		_set_selected_light_level_tab(0)
		_update()

var selected_tab: int
# Index is the light level tab
var original_textures: Array[Texture2D] = []
var textures: Array[Texture2D] = []
var png_regex: RegEx


func has_changes():
	return not (
		textures == original_textures
		and texture.dither_transition_amount == dithered_transition_config.value
	)


func _ready():
	png_regex = RegEx.new()
	png_regex.compile(".*\\.png$")
	
	# Just in case...
	effects_container.visible = false
	show_hide_effects.text = "Show Effects"
	
	# Every time there is a data update, reimport the texture resource
	PickyPixelsManager.get_instance().updated.connect(_update)
	
	_update()


func _set_light_levels(value):
	
	light_levels_config.value = value
	
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


func _warn(message: String, can_cancel: bool):
	save.disabled = true
	save.tooltip_text = "Fix issues before saving."
	cancel.disabled = not can_cancel
	cancel.tooltip_text = "Discard changes." if can_cancel else "No changes to discard."
	warning.text = message
	warning.visible = true


# Called whenever a texture or light level is added or removed.
func _update():
	if not is_node_ready():
		await ready
	
	var manager = PickyPixelsManager.get_instance()
	
	# First make sure there is a project and texture resource
	if manager.project_data == null:
		_warn("Missing project data. This is likely due to a plugin bug. Try restarting your project.", false)
		return
	
	if texture == null:
		_warn("Missing PickyPixelsImageTexture resource. This is likely due to a plugin bug. Try restarting your project.", false)
		return
	
	var result = manager.is_valid_texture_config(textures, dithered_transition_config.value)
	var is_changes = has_changes()
	
	# If there are no issues, then enable the save button
	# if there are changes to save.
	if result == PickyPixelsManager.TexturesStatus.OK:
		if is_changes:
			save.disabled = false
			save.tooltip_text = ""
			cancel.disabled = false
			cancel.tooltip_text = "Discard changes."
			warning.visible = false
		else:
			save.disabled = false
			save.tooltip_text = "Recompile texture."
			cancel.disabled = true
			cancel.tooltip_text = "No changes to discard."
			warning.visible = false
	else:
		match result:
			PickyPixelsManager.TexturesStatus.ERR_TEXTURE_NULL:
				_warn("Light levels must all have textures.", is_changes)
			PickyPixelsManager.TexturesStatus.ERR_TEXTURE_SIZE_MISMATCH:
				_warn("Light level textures must all be the same size.", is_changes)
			PickyPixelsManager.TexturesStatus.ERR_UNKNOWN_COLOR:
				_warn("All colors must be from the selected project's color palette.", is_changes)
			PickyPixelsManager.TexturesStatus.ERR_NOT_ENOUGH_RAMPS:
				_warn("Saving will create too many color ramps. Try removing a light layer or making textures more similar.", is_changes)
			_:
				_warn("Encountered an unknown issue (Error code: " + str(result) + ").", is_changes)
	if is_changes:
		made_changes.emit(texture)
	else:
		no_changes.emit(texture)


func _on_texture_display_loaded_texture(texture):
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


func _on_light_levels_config_changed(value: int) -> void:
	_set_light_levels(value)
	_update()


func _on_dithered_transition_config_changed(value: int) -> void:
	_update()


func _on_save_pressed():
	PickyPixelsManager.get_instance().compile_texture(texture, textures, dithered_transition_config.value)
	original_textures = textures.duplicate()
	_set_selected_light_level_tab(0)
	_update()


func _on_cancel_pressed():
	textures = original_textures.duplicate()
	dithered_transition_config.value = texture.dither_transition_amount
	_set_light_levels(textures.size())
	_set_selected_light_level_tab(0)
	_update()


func _on_show_hide_effects_pressed() -> void:
	if show_hide_effects.button_pressed:
		show_hide_effects.text = "Hide Effects"
	else:
		show_hide_effects.text = "Show Effects"
	effects_container.visible = show_hide_effects.button_pressed
