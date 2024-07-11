@tool
class_name PickyPixelsShaderMaterial
extends ShaderMaterial

func _init():
	if not OS.has_feature("editor"):
		set_shader_parameter("in_editor", false)
	else:
		set_shader_parameter("in_editor", Engine.is_editor_hint())
