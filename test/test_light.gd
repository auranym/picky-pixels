extends PointLight2D

@export_range(0.0, 4.0, 0.01) var x_speed = 1.0
@export_range(0.0, 4.0, 0.01) var y_speed = 1.0
@export_range(0.0, 32.0, 0.1) var x_dist = 8.0
@export_range(0.0, 32.0, 0.1) var y_dist = 8.0
@export_range(8, 64, 1) var light_size = 32

var time = 0

func _ready():
	(texture as GradientTexture2D).width = light_size
	(texture as GradientTexture2D).height = light_size
	time = randf_range(0, 2 * PI)

func _process(delta):
	time += delta
	
	offset.x = x_dist * cos(PI * time * x_speed)
	offset.y = y_dist * sin(PI * time * y_speed)
