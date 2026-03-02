extends Area2D

@export var speed = 700.0
@export var damage = 1
var direction = Vector2.ZERO

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta):
	position += direction * speed * delta

func _on_area_entered(area):
	if area.has_method("take_damage"):
		area.take_damage(damage)
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	if body is CharacterBody2D:
		body.velocity += direction.normalized() * 150.0
	queue_free()	
