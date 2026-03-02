extends RigidBody2D

@export var exp_value = 1

func _ready():
	body_entered.connect(_on_body_entered)

	linear_velocity = Vector2(randf_range(-80, 80), randf_range(-200, -100))

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.add_exp(exp_value)
		call_deferred("queue_free")
