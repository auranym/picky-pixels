@tool
extends Control

signal edit_selected(index: int)

const SPRITE_ITEM = preload("res://addons/picky-pixels/ui/library/sprite_item.tscn")
const LOAD_PALETTE_TOOLTIP = "Load color palette from an image. Project will be recompiled."
const RECOMPILE_TOOLTIP = "Recompile sprite encodings and color ramps. May free up space for new ramps."

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

var _project_data: PickyPixelsProjectData = null
@export var project_data: PickyPixelsProjectData:
	get: return _project_data
	set(d):
		if _project_data != null:
			_project_data.changed.disconnect(_import_project_data)
		
		if not is_node_ready():
			await ready
		
		_project_data = d
		_project_data.changed.connect(_import_project_data)
		_import_project_data()

@onready var color_palette = $VBoxContainer/HBoxContainer/ColorPalette
@onready var item_container = $VBoxContainer/ScrollContainer/ItemContainer
@onready var new_item = $VBoxContainer/ScrollContainer/ItemContainer/NewItem
@onready var color_ramps_indicator = $VBoxContainer/HBoxContainer/VBoxContainer/ColorRampsIndicator
@onready var recompile_button = $VBoxContainer/HBoxContainer/VBoxContainer/RecompileButton
@onready var load_palette_button = $VBoxContainer/HBoxContainer/VBoxContainer/LoadPaletteButton
@onready var palette_file_dialog = $PaletteFileDialog
@onready var recompile_overlay = $RecompileOverlay
@onready var recompile_label = $RecompileOverlay/RecompileLabel
var _recompile_in_progress: bool


func _ready():
	recompile_button.icon = get_theme_icon("Reload", "EditorIcons")
	recompile_button.tooltip_text = RECOMPILE_TOOLTIP
	load_palette_button.icon = get_theme_icon("ColorPick", "EditorIcons")
	load_palette_button.tooltip_text = LOAD_PALETTE_TOOLTIP
	recompile_overlay.visible = false


func _import_project_data():
	for child in item_container.get_children():
		if not child == new_item:
			item_container.remove_child(child)
	
	if _project_data == null:
		var tooltip_warning = "\n\n(Invalid project. This may be a bug, try restarting.)"
		recompile_button.disabled = buttons_disabled
		recompile_button.tooltip_text = RECOMPILE_TOOLTIP + tooltip_warning
		load_palette_button.disabled = buttons_disabled
		load_palette_button.tooltip_text = LOAD_PALETTE_TOOLTIP + tooltip_warning
		return
	
	for i in _project_data.sprites.size():
		var sprite = _project_data.sprites[i]
		if sprite == null:
			continue
		
		var sprite_item = SPRITE_ITEM.instantiate()
		sprite_item.data = sprite
		sprite_item.edit_selected.connect(func(): _on_sprite_item_edit_selected(i))
		sprite_item.delete_selected.connect(func(): _on_sprite_item_delete_selected(i))
		item_container.add_child(sprite_item)
	
	item_container.move_child(new_item, -1)
	
	color_palette.colors = _project_data.palette
	color_ramps_indicator.ramps = _project_data.ramps.size()


func _recompile(new_palette: Array[Color]):
	# Make sure there is no current thread
	if _recompile_in_progress:
		print("Recompile already in progress!")
		return
	
	# Init recompilation
	recompile_overlay.visible = true
	_recompile_in_progress = true
	var new_project = PickyPixelsProjectData.new()
	new_project.palette = new_palette
	
	# Iterate over all sprites to recalculate ramps and textures
	var num_sprites = _project_data.sprites.size()
	for i in num_sprites:
		recompile_label.text = "Compiling sprite ({i}/{num}).".format({ "i": str(i), "num": num_sprites })
		await get_tree().process_frame
		
		new_project.create_sprite()
		var sprite = _project_data.sprites[i]
		if new_project.is_valid_base_textures(sprite.base_textures) == PickyPixelsProjectData.TexturesStatus.OK:
			new_project.update_sprite(i, sprite.base_textures)
		else:
			new_project.sprites[i].invalid_textures = true
	
	recompile_label.text = "Finishing up."
	await get_tree().process_frame
	
	# Update project data!
	for i in _project_data.sprites.size():
		_project_data.sprites[i].texture = new_project.sprites[i].texture
	_project_data.ramps = new_project.ramps
	
	# Hide compile UI
	_recompile_in_progress = false
	recompile_overlay.visible = false


func _on_new_item_clicked():
	_project_data.create_sprite()


func _on_sprite_item_edit_selected(index: int):
	edit_selected.emit(index)


func _on_sprite_item_delete_selected(index: int):
	_project_data.delete_sprite(index)


func _on_recompile_button_pressed():
	_recompile(_project_data.palette)


func _on_load_palette_button_pressed():
	palette_file_dialog.show()


func _on_palette_file_dialog_file_selected(path):
	#var img = Image.load_from_file(path)
	print("updated colors")
	#_recompile()

