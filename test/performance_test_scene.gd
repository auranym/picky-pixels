extends Node2D

#const TEST_SPRITE = preload("res://test/control_sprite.tscn")
const TEST_SPRITE = preload("res://addons/picky-pixels/nodes/picky_sprite_2d/picky_sprite_2d.tscn")
const TEST_LIGHT = preload("res://test/test_light.tscn")

@export var sprites: int = 50
@export var lights: int = 5

# GOAL:
# Get this scene to run at a consistent 60 FPS with 300 sprites and 32 lights

func _ready():
	var x_dim = max(1, floor(sqrt(sprites * 4.0/3.0)))
	var y_dim = round(x_dim * 3.0/4.0)
	randomize()
	for x in x_dim:
		for y in y_dim:
			var pos = 32.0 * Vector2(x, y) + Vector2(16, 16)
			var sprite = TEST_SPRITE.instantiate()
			sprite.position = pos
			add_child(sprite)
	
	for _i in lights:
		var pos = Vector2(randf_range(0.0, 32.0 * x_dim), randf_range(0.0, 32.0 * y_dim)) + Vector2(16, 16)
		var light = TEST_LIGHT.instantiate()
		light.position = pos
		add_child(light)
		light.play_random()
