extends Sprite2D

# RESOURCES:
# https://github.com/OverloadedOrama/Godot-ComputeShader-GameOfLife
# https://github.com/nekotogd/Raytracing_Godot4/tree/master
# https://pastebin.com/pbGGjrE8, https://pastebin.com/92cvEagc

# Shader variables
var rd: RenderingDevice
var shader: RID
var pipeline: RID
var params_buffer: RID
var uniform_set: RID
var image_size := texture.get_image().get_size()
var global_time := 0.0

func _ready():
	RenderingServer.call_on_render_thread(_setup_compute)


func _process(delta):
	global_time += delta
	RenderingServer.call_on_render_thread(_render_compute)


func _setup_compute():
	# Rendering device to handle compute commands
	rd = RenderingServer.get_rendering_device()
	
	# Shader and pipeline
	var shader_file = load("res://test/compute_shader/compute_shader_sprite.glsl")
	var shader_spirv = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)
	
	# Image data
	var image = texture.get_image()
	image.convert(Image.FORMAT_RGBAF)
	
	# Output image buffer
	var fmt_output = RDTextureFormat.new()
	fmt_output.width = image_size.x
	fmt_output.height = image_size.y
	fmt_output.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	fmt_output.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
		| RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
		| RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
		| RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	)
	var image_output = rd.texture_create(fmt_output, RDTextureView.new(), [Image.create(image_size.x, image_size.y, false, Image.FORMAT_RGBAF).get_data()])
	var image_output_uniform = RDUniform.new()
	image_output_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	image_output_uniform.binding = 1
	image_output_uniform.add_id(image_output)
	
	
	# Input image buffer
	var fmt_input = RDTextureFormat.new()
	fmt_input.width = image_size.x
	fmt_input.height = image_size.y
	fmt_input.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	fmt_input.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
		| RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
	)
	var image_input = rd.texture_create(fmt_input, RDTextureView.new(), [image.get_data()])
	var image_input_uniform = RDUniform.new()
	image_input_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	image_input_uniform.binding = 0
	image_input_uniform.add_id(image_input)
	
	# Params buffer
	var params = PackedFloat32Array([
		global_time,
		position.x,
		position.y
	]).to_byte_array()
	params_buffer = rd.storage_buffer_create(params.size(), params)
	var params_uniform = RDUniform.new()
	params_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	params_uniform.binding = 2
	params_uniform.add_id(params_buffer)
	
	# Bind uniforms and buffers to send to the GPU
	uniform_set = rd.uniform_set_create([
		image_input_uniform,
		image_output_uniform,
		params_uniform
	], shader, 0)
	
	# Set texture to Texture2DRD, which will read from the shader output
	# without the need for reading the shader output back to CPU
	var texture_rd = Texture2DRD.new()
	texture_rd.texture_rd_rid = image_output
	texture = texture_rd


func _render_compute():
	# Remake params and update buffer
	var params = PackedFloat32Array([
		global_time,
		position.x,
		position.y
	]).to_byte_array()
	rd.buffer_update(params_buffer, 0, params.size(), params)
	
	# Start a compute list, recording commands to send to the GPU
	var compute_list = rd.compute_list_begin()
	# Bind the pipeline, this tells the GPU what shader to use
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	# Binds the uniform set with the data we want to give our shader
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	# Dispatch (X,Y,Z) work groups
	rd.compute_list_dispatch(compute_list, image_size.x, image_size.y, 1)
	# Tell the GPU we are done with this compute task
	rd.compute_list_end()
