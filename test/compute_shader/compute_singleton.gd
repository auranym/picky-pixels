class_name ComputeSingleton
extends Node

const SHADER = preload("res://test/compute_shader/compute_singleton.glsl")

@export var textures: Array[TextureRect]

var rd: RenderingDevice
var image_size: Vector2i
var shader: RID
var pipeline: RID
var output_uniform: RDUniform

func _ready():
	RenderingServer.call_on_render_thread(_compute)


func _compute():
	rd = RenderingServer.get_rendering_device()
	
	image_size = Vector2i(0, 0)
	for tex in textures:
		var size = tex.texture.get_size()
		image_size.x = max(image_size.x, size.x)
		image_size.y = max(image_size.y, size.y)
	
	# Shader and pipeline
	var shader_spirv = SHADER.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)
	
	# Output image buffer
	var fmt_output = RDTextureFormat.new()
	fmt_output.width = image_size.x
	fmt_output.height = image_size.y
	fmt_output.format = RenderingDevice.DATA_FORMAT_R32_UINT
	fmt_output.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
		| RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
		| RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
		| RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	)
	var output = rd.texture_create(fmt_output, RDTextureView.new(), [Image.create(image_size.x, image_size.y, false, Image.FORMAT_RF).get_data()])
	output_uniform = RDUniform.new()
	output_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	output_uniform.binding = 2
	output_uniform.add_id(output)
	
	for tex in textures:
		_compute_texture(tex)


func _compute_texture(t: TextureRect):
	var image = t.texture.get_image()
	image.convert(Image.FORMAT_RF)
	var size = image.get_size()
	
	# Input image buffer
	var fmt = RDTextureFormat.new()
	fmt.width = size.x
	fmt.height = size.y
	fmt.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	fmt.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
		| RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
	)
	var img = rd.texture_create(
		fmt,
		RDTextureView.new(),
		[image.get_data()]
	)
	var img_uniform = RDUniform.new()
	img_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	img_uniform.binding = 0
	img_uniform.add_id(img)
	
	var uniform_set = rd.uniform_set_create([
		img_uniform,
		output_uniform
	], shader, 0)
	
	# Start a compute list, recording commands to send to the GPU
	var compute_list = rd.compute_list_begin()
	# Bind the pipeline, this tells the GPU what shader to use
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	# Binds the uniform set with the data we want to give our shader
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	# Dispatch (X,Y,Z) work groups
	rd.compute_list_dispatch(compute_list, size.x, size.y, 1)
	# Tell the GPU we are done with this compute task
	rd.compute_list_end()
