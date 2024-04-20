extends TextureRect

const SHADER = preload("res://test/compute_shader/compute_singleton_consumer.glsl")

@export var compute_singleton: ComputeSingleton


func _ready():
	RenderingServer.call_on_render_thread(_compute)


func _compute():
	var rd = RenderingServer.get_rendering_device()
	
	var image_size = compute_singleton.image_size
	
	# Shader and pipeline
	var shader_spirv = SHADER.get_spirv()
	var shader = rd.shader_create_from_spirv(shader_spirv)
	var pipeline = rd.compute_pipeline_create(shader)
	
	# Output image buffer
	var fmt_output = RDTextureFormat.new()
	fmt_output.width = compute_singleton.image_size.x
	fmt_output.height = compute_singleton.image_size.y
	fmt_output.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	fmt_output.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
		| RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
		| RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
		| RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	)
	var output = rd.texture_create(fmt_output, RDTextureView.new(), [Image.create(image_size.x, image_size.y, false, Image.FORMAT_RGBAF).get_data()])
	var output_uniform = RDUniform.new()
	output_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	output_uniform.binding = 1
	output_uniform.add_id(output)
	
	# Assign output to texture
	var texture_rd = Texture2DRD.new()
	texture_rd.texture_rd_rid = output
	texture = texture_rd
	
	var uniform_set = rd.uniform_set_create([
		compute_singleton.output_uniform,
		output_uniform
	], shader, 0)
	
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
