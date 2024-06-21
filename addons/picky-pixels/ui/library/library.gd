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
var _recompile_thread: Thread
var _recompile_mutex: Mutex
var _recompile_cancelled: bool
var _recompile_status: String


func _ready():
	_recompile_thread = Thread.new()
	_recompile_mutex = Mutex.new()
	recompile_button.icon = get_theme_icon("Reload", "EditorIcons")
	recompile_button.tooltip_text = RECOMPILE_TOOLTIP
	load_palette_button.icon = get_theme_icon("ColorPick", "EditorIcons")
	load_palette_button.tooltip_text = LOAD_PALETTE_TOOLTIP
	recompile_overlay.visible = false


func _exit_tree():
	if _recompile_thread != null and _recompile_thread.is_started():
		print("Cancelling compilation...")
		_recompile_mutex.lock()
		_recompile_cancelled = true
		_recompile_mutex.unlock()
		_recompile_thread.wait_to_finish()


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
	if _recompile_thread.is_started():
		print("Recompile already in progress!")
		return
	
	# Safe to do without locking since
	# this should never be reached while
	# thread is still running 
	#_recompile_status = "Compilation started."
	recompile_overlay.visible = true
	_recompile_cancelled = false
	var base_textures: Array[Array] = []
	for sprite in _project_data.sprites:
		base_textures.push_back(sprite.base_textures.duplicate())
	_recompile_thread.start(_recompile_thread_func.bind(
		new_palette,
		base_textures
	))
	
	# Wait for thread to finish
	while _recompile_thread.is_alive():
		#recompile_label.text = _recompile_status
		await get_tree().process_frame
	# Join thread
	var new_project = _recompile_thread.wait_to_finish()
	print(new_project.ramps)
	print(new_project.palette)
	recompile_overlay.visible = false


func _recompile_thread_func(
	new_palette: Array[Color],
	base_textures: Array[Array]
) -> PickyPixelsProjectData:
	
	var new_project = PickyPixelsProjectData.new()
	new_project.palette = new_palette
	
	for i in base_textures.size():
		#_recompile_mutex.lock()
		#_recompile_status = "Compiling sprite (" + str(i+1) + "/" + str(base_textures.size()) + ")"
		#_recompile_mutex.unlock()
		
		new_project.create_sprite()
		if new_project.is_valid_base_textures(base_textures[i]):
			new_project.update_sprite(i, base_textures[i])
		else:
			new_project.sprites[i].invalid_textures = true
	
	return new_project


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

