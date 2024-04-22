extends Node

signal updated

const POINT_LIGHT_ENCODER = preload("res://test/optimization/picky_lights_encoder_2/point_light_encoder_2.glsl")

var encoded_lights_image := Texture2DRD.new()

# Internal variables
var _rd: RenderingDevice
var _shader: RID
var _pipeline: RID
var _light_textures_uniform: RDUniform
var _data_buffer_uniform: RDUniform
var _image_output_uniform: RDUniform
# TEMP FOR TESTING
var _lights_changed = 0

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
	
	_light_textures_uniform = RDUniform.new()
	_light_textures_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	_light_textures_uniform.binding = 0
	
	_data_buffer_uniform = RDUniform.new()
	_data_buffer_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	_data_buffer_uniform.binding = 1
	
	_image_output_uniform = RDUniform.new()
	_image_output_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	_image_output_uniform.binding = 2


func _compute():
	# TEMP FOR TESTING!
	#if _lights_changed != 0:
		#_lights_changed -= 1
		#return
	#_lights_changed = 2
	
	# Find all point lights
	var point_lights: Array[PointLight2D] = []
	for light in get_tree().get_nodes_in_group("picky_light"):
		if light is PointLight2D:
			point_lights.push_back(light)
	
	# Do nothing if there are none
	if point_lights.size() == 0:
		return
	
	# Else, collect data for them
	var point_light_images: Array[Image] = []
	var largest_image_size = Vector2.ZERO
	#var point_light_texture_sizes: Array[Vector2i] = []
	var point_light_positions: Array[Vector2i] = []
	# ...and the extents of the output image as well
	var image_size = Vector2i(0, 0)
	var image_pos = Vector2i(0, 0)
	for point_light in point_lights:
		var image = point_light.texture.get_image()
		var size = image.get_size()
		var pos = Vector2i(point_light.position) - (size / 2)
		point_light_images.push_back(image)
		#point_light_texture_sizes.push_back(size)
		point_light_positions.push_back(pos)
		largest_image_size.x = max(largest_image_size.x, size.x)
		largest_image_size.y = max(largest_image_size.y, size.y)
		image_size.x = max(image_size.x, size.x + pos.x)
		image_size.y = max(image_size.y, size.y + pos.y)
		image_pos.x = min(image_pos.x, pos.x)
		image_pos.y = min(image_pos.y, pos.y)
	
	# Once we know the max size, we can grow all images to that size
	# and then convert them to the correct format
	var point_light_image_data = []
	for image in point_light_images:
		image.crop(largest_image_size.x, largest_image_size.y)
		image.convert(Image.FORMAT_RGBAF)
		point_light_image_data.push_back(image.get_data())
	
	# Next, create a new image2DArray and add it to the uniform
	var fmt = RDTextureFormat.new()
	fmt.width = largest_image_size.x
	fmt.height = largest_image_size.y
	fmt.texture_type = RenderingDevice.TEXTURE_TYPE_2D_ARRAY
	fmt.array_layers = point_lights.size()
	fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	fmt.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
		| RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
	)
	var point_light_image_array = _rd.texture_create(fmt, RDTextureView.new(), point_light_image_data)
	# Clean up previous RIDs
	for rid in _light_textures_uniform.get_ids():
		_rd.free_rid(rid)
	_light_textures_uniform.clear_ids()
	_light_textures_uniform.add_id(point_light_image_array)
	
	# Update the data buffer.
	# Do this 4 bytes at a time, just in case.
	# Static-length data:
	var data = [
		image_pos.x, image_pos.y,
		point_lights.size(),
	]
	# Variable length data:
	for pos in point_light_positions:
		data.append_array([pos.x, pos.y])
	# Convert to PackedByteArray
	data = PackedInt32Array(data).to_byte_array()
	var data_buffer = _rd.storage_buffer_create(data.size(), data)
	# Clean up previous buffer and make a new one
	for rid in _data_buffer_uniform.get_ids():
		_rd.free_rid(rid)
	_data_buffer_uniform.clear_ids()
	_data_buffer_uniform.add_id(data_buffer)
	
	# Finally, create a new output image buffer
	fmt = RDTextureFormat.new()
	fmt.width = image_size.x
	fmt.height = image_size.y
	fmt.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	fmt.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
		| RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
		| RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
		| RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	)
	var image_output = _rd.texture_create(fmt, RDTextureView.new(), [Image.create(image_size.x, image_size.y, false, Image.FORMAT_RF).get_data()])
	# Update texture
	encoded_lights_image.texture_rd_rid = image_output
	# Clean up previous image
	for rid in _image_output_uniform.get_ids():
		_rd.free_rid(rid)
	_image_output_uniform.clear_ids()
	_image_output_uniform.add_id(image_output)
	
	# Make a uniform set
	var uniform_set = _rd.uniform_set_create([
		_light_textures_uniform,
		_data_buffer_uniform,
		_image_output_uniform
	], _shader, 0)
	
	# Start a compute list, recording commands to send to the GPU
	var compute_list = _rd.compute_list_begin()
	# Bind the pipeline, this tells the GPU what shader to use
	_rd.compute_list_bind_compute_pipeline(compute_list, _pipeline)
	# Binds the uniform set with the data we want to give our shader
	_rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	# Dispatch (X,Y,Z) work groups
	_rd.compute_list_dispatch(compute_list, image_size.x, image_size.y, 1)
	# Tell the GPU we are done with this compute task
	_rd.compute_list_end()
