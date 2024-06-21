class_name PickyPixelsShaderMaterial
extends ShaderMaterial

func _init():
	set_shader_parameter("in_editor", Engine.is_editor_hint())
