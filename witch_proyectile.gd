extends Area2D

@export var speed: float = 250.0
@export var damage: int = 1

var direction: Vector2 = Vector2.ZERO

func _ready():
	body_entered.connect(_on_body_entered)
	
func _physics_process(delta):
	position += direction * speed * delta
	if direction.x > 0:
		$AnimatedSprite2D.flip_h = true
	else:
		$AnimatedSprite2D.flip_h = false
func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(damage)
		queue_free()
		
	elif body.is_in_group("world"):
		impact()


func impact():
	$AudioImpact.play()
	await $AudioImpact.finished
	queue_free()
