extends Area2D

@export var speed = 300.0
@export var damage = 1
var direction = Vector2.ZERO
var flipped = false

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	if not flipped:
		$Sprite2D.flip_h = direction.x < 0
		flipped = true
	global_position += direction * speed * delta
	if global_position.x > 700:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(damage)
	queue_free()
