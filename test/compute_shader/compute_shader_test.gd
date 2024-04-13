extends Node2D

const COMPUTE_SHADER_SPRITE = preload("res://test/compute_shader/compute_shader_sprite.tscn")

@export var sprites: int = 10

# Called when the node enters the scene tree for the first time.
func _ready():
	var x_dim = max(1, floor(sqrt(sprites * 4.0/3.0)))
	var y_dim = round(x_dim * 3.0/4.0)
	var sprite_size = null
	for x in x_dim:
		for y in y_dim:
			var sprite: Sprite2D = COMPUTE_SHADER_SPRITE.instantiate()
			if sprite_size == null:
				sprite_size = sprite.texture.get_size()
			sprite.position = Vector2(x * sprite_size.x, y * sprite_size.y) + (sprite_size / 2.0)
			add_child(sprite)
