extends PointLight2D

@onready var animation_player = $AnimationPlayer

func play_random():
	animation_player.speed_scale = randf_range(0.5, 2.0)
	var r = randi_range(0, 2)
	match r:
		0: animation_player.play("diamond")
		1: animation_player.play("pingpong_x")
		2: animation_player.play("pingpong_y")
	animation_player.seek(randf_range(0.0, 4.0))
