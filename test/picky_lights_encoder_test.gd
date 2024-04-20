extends Sprite2D

const PICKY_LIGHTS_ENCODER_TEST = preload("res://test/picky_lights_encoder_test.glsl")

var _rd: RenderingDevice
var _shader: RID
var _pipeline: RID
var _output_image_uniform: RDUniform
 ## TEMP
var image_size = Vector2(700, 500)

func _ready():
	RenderingServer.call_on_render_thread(_setup_compute)
	PickyLightsEncoder.updated.connect(_call_compute)


# FOR TESTING
@onready var x_pos = $PointLight2D2.position.x
var time = 0
func _process(delta):
	time += delta
	$PointLight2D2.position.x = x_pos + 30.0 * sin(PI * time)


func _call_compute():
	RenderingServer.call_on_render_thread(_compute)


func _setup_compute():
	_rd = RenderingServer.get_rendering_device()
	
	# Shader and pipeline
	var shader_spirv = PICKY_LIGHTS_ENCODER_TEST.get_spirv()
	_shader = _rd.shader_create_from_spirv(shader_spirv)
	_pipeline = _rd.compute_pipeline_create(_shader)
	
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
	var output = _rd.texture_create(fmt_output, RDTextureView.new(), [Image.create(image_size.x, image_size.y, false, Image.FORMAT_RGBAF).get_data()])
	_output_image_uniform = RDUniform.new()
	_output_image_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	_output_image_uniform.binding = 1
	_output_image_uniform.add_id(output)
	
	# Assign texture to Texture2DRD
	var texture_rd = Texture2DRD.new()
	texture_rd.texture_rd_rid = output
	texture = texture_rd


func _compute():
	var uniform_set = _rd.uniform_set_create([
		PickyLightsEncoder.encoded_lights_image_uniform,
		_output_image_uniform
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
	#
	#_rd.barrier(RenderingDevice.BARRIER_MASK_COMPUTE)
	#
	## Clean up
	#_rd.free_rid(uniform_set)
