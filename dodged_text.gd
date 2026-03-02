extends Node2D

@export var float_speed := 40.0
@export var lifetime := 1.0

var time_passed := 0.0

@onready var sprite = $Sprite2D

func _process(delta):
	position.y -= float_speed * delta

	time_passed += delta

	sprite.modulate.a = 1.0 - (time_passed / lifetime)

	if time_passed >= lifetime:
		queue_free()
