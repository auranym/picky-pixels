extends Sprite2D

const PICKY_SPRITE_2D = preload("res://test/optimization/picky_sprite_2d/picky_sprite_2d.glsl")

@export var textures: Array[Texture2D]

# Shader variables
var _rd: RenderingDevice
var _shader: RID
var _pipeline: RID
var _sprite_textures_uniform: RDUniform
var _light_textures_uniform: RDUniform
var _data_buffer_uniform: RDUniform
var _image_output_uniform: RDUniform

# TEST
var image_size = Vector2(32, 32)

func _ready():
	RenderingServer.call_on_render_thread(_setup_compute)


func _process(delta):
	RenderingServer.call_on_render_thread(_compute)


func _setup_compute():
	_rd = RenderingServer.get_rendering_device()
	
	var shader_spirv = PICKY_SPRITE_2D.get_spirv()
	_shader = _rd.shader_create_from_spirv(shader_spirv)
	_pipeline = _rd.compute_pipeline_create(_shader)
	
	# TEST
	var image_data_array = []
	for tex in textures:
		var image = tex.get_image()
		image.convert(Image.FORMAT_RGBAF)
		image_data_array.push_back(image.get_data())
	
	# Input sprite textures buffer
	var fmt = RDTextureFormat.new()
	fmt.width = image_size.x
	fmt.height = image_size.y
	fmt.texture_type = RenderingDevice.TEXTURE_TYPE_2D_ARRAY
	fmt.array_layers = textures.size()
	fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	fmt.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
		| RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
	)
	var sprite_textures = _rd.texture_create(fmt, RDTextureView.new(), image_data_array)
	_sprite_textures_uniform = RDUniform.new()
	_sprite_textures_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	_sprite_textures_uniform.binding = 0
	_sprite_textures_uniform.add_id(sprite_textures)
	
	# Input light textures buffer (initialize with a dummy image)
	fmt = RDTextureFormat.new()
	fmt.width = 1
	fmt.height = 1
	fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	fmt.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
		| RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
	)
	var img = Image.new()
	img.crop(1, 1)
	img.convert(Image.FORMAT_RGBAF)
	var light_texture = _rd.texture_create(fmt, RDTextureView.new(), [img.get_data()])
	_light_textures_uniform = RDUniform.new()
	_light_textures_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	_light_textures_uniform.binding = 1
	_light_textures_uniform.add_id(light_texture)
	
	# Data buffer (fill with dummy data)
	var data = PackedByteArray([0])
	var data_buffer = _rd.storage_buffer_create(data.size(), data)
	_data_buffer_uniform = RDUniform.new()
	_data_buffer_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	_data_buffer_uniform.binding = 2
	_data_buffer_uniform.add_id(data_buffer)
	
	# Output image buffer
	fmt = RDTextureFormat.new()
	fmt.width = image_size.x
	fmt.height = image_size.y
	fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	fmt.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
		| RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
		| RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
		| RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	)
	var image_output = _rd.texture_create(fmt, RDTextureView.new(), [Image.create(image_size.x, image_size.y, false, Image.FORMAT_RGBAF).get_data()])
	_image_output_uniform = RDUniform.new()
	_image_output_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	_image_output_uniform.binding = 3
	_image_output_uniform.add_id(image_output)
	
	var texture_rd = Texture2DRD.new()
	texture_rd.texture_rd_rid = image_output
	texture = texture_rd


func _compute():
	# First detect if there are any overlapping PointLight2Ds.
	# TODO detect overlap
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
	var point_light_texture_sizes: Array[Vector2i] = []
	for point_light in point_lights:
		var image = point_light.texture.get_image()
		point_light_images.push_back(image)
		var size = image.get_size()
		point_light_texture_sizes.push_back(size)
		largest_image_size.x = max(largest_image_size.x, size.x)
		largest_image_size.y = max(largest_image_size.y, size.y)
	
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
	
	# Finally, update the data buffer.
	# Do this 4 bytes at a time, just in case.
	# Static-length data:
	var data = PackedInt32Array([
		textures.size(),
		point_lights.size(),
		image_size.x, image_size.y,
	])
	# Variable length data:
	#for size in point_light_texture_sizes:
		#data.append_array([size.x, size.y])
	# Convert to PackedByteArray
	data = data.to_byte_array()
	var data_buffer = _rd.storage_buffer_create(data.size(), data)
	# Clean up previous buffer and make a new one
	for rid in _data_buffer_uniform.get_ids():
		_rd.free_rid(rid)
	_data_buffer_uniform.clear_ids()
	_data_buffer_uniform.add_id(data_buffer)
	
	var uniform_set = _rd.uniform_set_create([
		_sprite_textures_uniform,
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
