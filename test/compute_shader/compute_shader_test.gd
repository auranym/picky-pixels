extends Node2D

const SPRITE = preload("res://test/compute_shader/compute_shader_sprite.tscn")
#const SPRITE = preload("res://test/compute_shader/control_sprite.tscn")
const TEST_LIGHT = preload("res://test/test_light.tscn")

@export var rows: int = 5
@export var cols: int = 6
@export var lights: int = 5

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	
	var sprite_size = null
	for x in cols:
		for y in rows:
			var sprite: Sprite2D = SPRITE.instantiate()
			if sprite_size == null:
				sprite_size = sprite.texture.get_size()
			sprite.position = Vector2(x * sprite_size.x, y * sprite_size.y) + (sprite_size / 2.0)
			add_child(sprite)
	 
	for _i in lights:
		var light: PointLight2D = TEST_LIGHT.instantiate()
		light.position = Vector2(
			randf_range(32.0, 32.0 * (cols-1)),
			randf_range(32.0, 32.0 * (rows-1))
		)
		light.play_random()
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
	
	position += delta * 500.0 * move_dir
