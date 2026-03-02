extends Node2D

@export var float_speed := 40.0
@export var lifetime := 1.0

var time_passed := 0.0

func _process(delta):
	position.y -= float_speed * delta
	time_passed += delta

	if time_passed >= lifetime:
		queue_free()
