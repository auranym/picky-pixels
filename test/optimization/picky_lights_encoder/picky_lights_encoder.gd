extends Node

signal updated

const POINT_LIGHT_ENCODER = preload("res://test/optimization/picky_lights_encoder/point_light_encoder.glsl")

## Used by PickySprite2D's.
## Binds an r32 uint image to binding=0.
var encoded_lights_image_uniform: RDUniform
## Used by PickySprite2D's.
## Binds data related to encoded_lights_image_uniform
## to a buffer with binding=1.
var encoded_lights_data_uniform: RDUniform

# Internal variables
var _rd: RenderingDevice
var _shader: RID
var _pipeline: RID
var _encoded_lights_data_buffer: RID

func _ready():
	RenderingServer.call_on_render_thread(_setup_compute)


func _process(_delta):
	RenderingServer.call_on_render_thread(_compute)


func _setup_compute():
	_rd = RenderingServer.get_rendering_device()
	
	# Shader and pipeline
	var shader_spirv = POINT_LIGHT_ENCODER.get_spirv()
	_shader = _rd.shader_create_from_spirv(shader_spirv)
	_pipeline = _rd.compute_pipeline_create(_shader)
	
	encoded_lights_image_uniform = RDUniform.new()
	encoded_lights_image_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	encoded_lights_image_uniform.binding = 0
	
	var empty_array = PackedInt32Array([0, 0]).to_byte_array()
	_encoded_lights_data_buffer = _rd.storage_buffer_create(empty_array.size(), empty_array)
	encoded_lights_data_uniform = RDUniform.new()
	encoded_lights_data_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	encoded_lights_data_uniform.binding = 1
	encoded_lights_data_uniform.add_id(_encoded_lights_data_buffer)


func _compute():
	# Find all point lights
	var point_lights: Array[PointLight2D] = []
	for light in get_tree().get_nodes_in_group("picky_light"):
		if light is PointLight2D:
			point_lights.push_back(light)
	
	# Do nothing if there are none
	if point_lights.size() == 0:
		return
	
	# If we reach here, then we find out the position and size of the
	# encoded image.
	#var image_size = Vector2i(0, 0)
	var image_size = Vector2i(700, 500)
	var image_pos = Vector2i(0, 0)
	#for light in point_lights:
		#var size = Vector2i(light.texture.get_size())
		#var pos = Vector2i(light.position) - (size / 2)
		#image_size.x = max(image_size.x, size.x + pos.x)
		#image_size.y = max(image_size.y, size.y + pos.y)
		#image_pos.x = min(image_pos.x, pos.x)
		#image_pos.y = min(image_pos.y, pos.y)
	
	# Set up the encoded image buffer
	var fmt = RDTextureFormat.new()
	fmt.width = image_size.x
	fmt.height = image_size.y
	fmt.format = RenderingDevice.DATA_FORMAT_R32_UINT
	fmt.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
		| RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
		| RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
		| RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	)
	var encoded_lights_image = _rd.texture_create(fmt, RDTextureView.new(), [Image.create(image_size.x, image_size.y, false, Image.FORMAT_RF).get_data()])
	# Clear existing IDs
	for rid in encoded_lights_image_uniform.get_ids():
		_rd.free_rid(rid)
	# Assign the new ID just created
	encoded_lights_image_uniform.clear_ids()
	encoded_lights_image_uniform.add_id(encoded_lights_image)
	
	# Update the encoded image data buffer
	var data = PackedInt32Array([image_pos.x, image_pos.y]).to_byte_array()
	_rd.buffer_update(
		_encoded_lights_data_buffer,
		0,
		data.size(),
		data
	)
	
	# Encode every point light
	for light in point_lights:
		_compute_point_light(light)
	
	_rd.barrier(RenderingDevice.BARRIER_MASK_COMPUTE)
	updated.emit()


func _compute_point_light(light: PointLight2D):
	var image = light.texture.get_image()
	image.convert(Image.FORMAT_RF)
	var size = image.get_size()
	
	# Light's texture image buffer
	var fmt = RDTextureFormat.new()
	fmt.width = size.x
	fmt.height = size.y
	fmt.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	fmt.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
		| RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
	)
	var light_texture = _rd.texture_create(
		fmt,
		RDTextureView.new(),
		[image.get_data()]
	)
	var light_texture_uniform = RDUniform.new()
	light_texture_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	light_texture_uniform.binding = 2
	light_texture_uniform.add_id(light_texture)
	
	# Light's additional data image buffer
	var pos = Vector2i(light.global_position) - Vector2i(size) / 2
	var data = PackedInt32Array([pos.x, pos.y]).to_byte_array()
	var light_data_buffer = _rd.storage_buffer_create(data.size(), data)
	var light_data_uniform = RDUniform.new()
	light_data_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	light_data_uniform.binding = 3
	light_data_uniform.add_id(light_data_buffer)
	
	# Make a uniform set
	var uniform_set = _rd.uniform_set_create([
		encoded_lights_image_uniform,
		encoded_lights_data_uniform,
		light_texture_uniform,
		light_data_uniform
	], _shader, 0)
	
	# Start a compute list, recording commands to send to the GPU
	var compute_list = _rd.compute_list_begin()
	# Bind the pipeline, this tells the GPU what shader to use
	_rd.compute_list_bind_compute_pipeline(compute_list, _pipeline)
	# Binds the uniform set with the data we want to give our shader
	_rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	# Dispatch (X,Y,Z) work groups
	_rd.compute_list_dispatch(compute_list, size.x, size.y, 1)
	# Tell the GPU we are done with this compute task
	_rd.compute_list_end()
	
	# Clean up
	_rd.free_rid(light_data_buffer)
	_rd.free_rid(light_texture)
