@tool
extends Control

const TOOLTIP = preload("res://addons/picky-pixels/ui/tooltip/tooltip.tscn")

@export var shader_material: ShaderMaterial
@onready var texture_rect = $TextureRect
@onready var panel = $Panel

# Called when the node enters the scene tree for the first time.
func _ready():
	texture_rect.texture = get_theme_icon("ShaderMaterial", "EditorIcons")
	panel.visible = false


func _make_custom_tooltip(for_text):
	var tooltip_node = TOOLTIP.instantiate()
	tooltip_node.text = for_text
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
