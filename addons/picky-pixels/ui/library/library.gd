@tool
extends Control

signal edit_selected(resource: Resource)

const TEXTURE_ITEM = preload("res://addons/picky-pixels/ui/library/texture_item.tscn")
const LOAD_PALETTE_TOOLTIP = "Load color palette from an image. Project will be recompiled."
const RECOMPILE_TOOLTIP = "Recompile texture encodings and color ramps. May free up space for new ramps."

@export var buttons_disabled: bool = false:
	get: return buttons_disabled
	set(val):
		buttons_disabled = val
		if not is_node_ready():
			await ready
		var tooltip_warning = "\n\n(Must close all open tabs.)" if buttons_disabled else ""
		recompile_button.disabled = buttons_disabled
		recompile_button.tooltip_text = RECOMPILE_TOOLTIP + tooltip_warning
		load_palette_button.disabled = buttons_disabled
		load_palette_button.tooltip_text = LOAD_PALETTE_TOOLTIP + tooltip_warning

@onready var main_shader_item = $VBoxContainer/ScrollContainer/VBoxContainer/ShaderContainer/MainShaderItem
@onready var canvas_item_shader_item = $VBoxContainer/ScrollContainer/VBoxContainer/ShaderContainer/CanvasItemShaderItem
@onready var color_palette = $VBoxContainer/HBoxContainer/ColorPalette
@onready var item_container = $VBoxContainer/ScrollContainer/VBoxContainer/ItemContainer
@onready var new_item = $VBoxContainer/ScrollContainer/VBoxContainer/ItemContainer/NewItem
@onready var color_ramps_indicator = $VBoxContainer/HBoxContainer/VBoxContainer/ColorRampsIndicator
@onready var recompile_button = $VBoxContainer/HBoxContainer/VBoxContainer/RecompileButton
@onready var load_palette_button = $VBoxContainer/HBoxContainer/VBoxContainer/LoadPaletteButton
@onready var palette_file_dialog = $PaletteFileDialog
@onready var recompile_overlay = $RecompileOverlay
@onready var recompile_label = $RecompileOverlay/RecompileLabel


func _ready():
	recompile_button.icon = get_theme_icon("Reload", "EditorIcons")
	recompile_button.tooltip_text = RECOMPILE_TOOLTIP
	load_palette_button.icon = get_theme_icon("ColorPick", "EditorIcons")
	load_palette_button.tooltip_text = LOAD_PALETTE_TOOLTIP
	recompile_overlay.visible = false
	
	var manager = PickyPixelsManager.get_instance()
	manager.updated.connect(_import_project_data)
	manager.recompile_started.connect(_on_picky_pixels_project_recompile_started)
	manager.recompile_finished.connect(_on_picky_pixels_project_recompile_finished)
	
	_import_project_data()


func _import_project_data():
	if not is_node_ready():
		await ready
	
	var manager = PickyPixelsManager.get_instance()
	
	for child in item_container.get_children():
		if not child == new_item:
			item_container.remove_child(child)
	
	if manager.project_data == null:
		var tooltip_warning = "\n\n(Invalid project. This may be a bug, try restarting.)"
		recompile_button.disabled = buttons_disabled
		recompile_button.tooltip_text = RECOMPILE_TOOLTIP + tooltip_warning
		load_palette_button.disabled = buttons_disabled
		load_palette_button.tooltip_text = LOAD_PALETTE_TOOLTIP + tooltip_warning
		return
	
	for i in manager.project_textures.size():
		var texture = manager.project_textures[i]
		if texture == null:
			continue
		
		var texture_item = TEXTURE_ITEM.instantiate()
		texture_item.texture = texture
		texture_item.edit_selected.connect(func(): edit_selected.emit(texture))
		item_container.add_child(texture_item)
	
	item_container.move_child(new_item, -1)
	
	main_shader_item.shader_material = manager.project_shader_material
	canvas_item_shader_item.shader_material = manager.canvas_item_shader_material
	color_palette.colors = manager.project_data.palette


func _process(_delta):
	if recompile_overlay.visible:
		recompile_label.text = PickyPixelsManager.get_instance().get_recompile_text_status()


func _on_recompile_button_pressed():
	PickyPixelsManager.get_instance().recompile_project()


func _on_load_palette_button_pressed():
	palette_file_dialog.show()


func _on_palette_file_dialog_file_selected(path):
	var img = Image.load_from_file(path)
	var colors_set = {}
	for x in img.get_width():
		for y in img.get_height():
			var color = img.get_pixel(x, y)
			if color.a8 == 255:
				colors_set[color] = true
	
	# Make sure it is the correct type...
	var colors: Array[Color] = []
	for key in colors_set.keys():
		var color: Color = key
		colors.push_back(color)
	
	PickyPixelsManager.get_instance().recompile_project(colors)


func _on_picky_pixels_project_recompile_started():
	recompile_overlay.visible = true


func _on_picky_pixels_project_recompile_finished():
	recompile_overlay.visible = false
