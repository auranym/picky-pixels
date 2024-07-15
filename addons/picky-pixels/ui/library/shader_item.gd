@tool
extends Control

const TOOLTIP = preload("res://addons/picky-pixels/ui/tooltip/tooltip.tscn")

enum Icon {
	SHADER_MATERIAL,
	CANVAS_ITEM_MATERIAL,
	STANDARD_MATERIAL_3D
}

@export var shader_material: ShaderMaterial

@export var label_text: String = "Shader":
	get: return label_text
	set(val):
		if not is_node_ready():
			await ready
		label_text = val
		label.text = label_text

@export var icon: Icon = Icon.SHADER_MATERIAL

@onready var texture_rect = $TextureRect
@onready var panel = $Panel
@onready var label = $Label


# Called when the node enters the scene tree for the first time.
func _ready():
	match icon:
		Icon.SHADER_MATERIAL:
			texture_rect.texture = get_theme_icon("ShaderMaterial", "EditorIcons")
		Icon.CANVAS_ITEM_MATERIAL:
			texture_rect.texture = get_theme_icon("CanvasItemMaterial", "EditorIcons")
		Icon.STANDARD_MATERIAL_3D:
			texture_rect.texture = get_theme_icon("StandardMaterial3D", "EditorIcons")
	panel.visible = false


func _make_custom_tooltip(for_text):
	if for_text.length() == 0 and shader_material == null:
		return
	
	var tooltip_node = TOOLTIP.instantiate()
	tooltip_node.text = ""
	
	if shader_material != null:
		tooltip_node.text += "(" + shader_material.resource_path + ")"
	if for_text.length() > 0:
		tooltip_node.text += ("\n\n" if shader_material != null else "") + for_text
	
	return tooltip_node


func _get_drag_data(at_position):
	if shader_material == null:
		return {}

	return {
		"type": "resource",
		"resource": shader_material
	}


func _on_mouse_entered():
	panel.visible = true


func _on_mouse_exited():
	panel.visible = false
