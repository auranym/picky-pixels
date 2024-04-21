extends Node2D

#const SPRITE = preload("res://test/control_sprite.tscn")
#const SPRITE = preload("res://test/picky_sprite_2d.tscn")
#const SPRITE = preload("res://addons/picky-pixels/nodes/picky_sprite_2d/picky_sprite_2d.tscn")
const SPRITE = preload("res://test/picky_sprite_2d.tscn")
const TEST_LIGHT = preload("res://test/test_light.tscn")

@export var rows: int = 10
@export var cols: int = 10
@export var lights: int = 5
@export var sprite_size: Vector2i = Vector2i(32, 32)

# GOAL:
# Get this scene to run at a consistent 60 FPS with 300 sprites and 32 lights

func _ready():
	for x in cols:
		for y in rows:
			var sprite = SPRITE.instantiate()
			sprite.position = Vector2(x * sprite_size.x, y * sprite_size.y) + (sprite_size / 2.0)
			add_child(sprite)
	 
	for _i in lights:
		var light: PointLight2D = TEST_LIGHT.instantiate()
		light.position = Vector2(
			randf_range(32.0, 32.0 * (cols-1)),
			randf_range(32.0, 32.0 * (rows-1))
		)
		#light.play_random()
		add_child(light)


func _process(delta):
	var move_dir = Vector2.ZERO
	if Input.is_action_pressed("ui_up"):
		move_dir.y += 1
	if Input.is_action_pressed("ui_down"):
		move_dir.y -= 1
	if Input.is_action_pressed("ui_left"):
		move_dir.x += 1
	if Input.is_action_pressed("ui_right"):
		move_dir.x -= 1
	
	position += Vector2(delta * 500.0 * move_dir).round()
