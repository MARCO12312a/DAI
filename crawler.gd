extends CharacterBody2D
@export var jump_range: float = 150.0
@onready var sprite = $AnimatedSprite2D
@onready var health_bar = $HealthBar

@export var max_health: float = 5
@export var speed: float = 500
@export var jump_force: float = -550
@export var gravity: float = 1400
@export var jump_cooldown: float = 1.0
@export var damage: float = 10
@export var friction: float = 600.0  

var health: float
var player: CharacterBody2D
var jump_timer: float = 0.0
var is_attacking = false

func _ready():
	player = get_tree().get_first_node_in_group("player")
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	sprite.play("run")
	sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	if player == null:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	if not is_attacking:
		var direction = sign(player.global_position.x - global_position.x)
		velocity.x = move_toward(velocity.x, direction * speed, speed * delta * 8)
		sprite.flip_h = direction > 0
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	jump_timer -= delta
	if is_on_floor() and jump_timer <= 0.0:
		var dist = global_position.distance_to(player.global_position)
		if not player.is_on_floor() and dist < jump_range:
			velocity.y = jump_force
			jump_timer = jump_cooldown

	move_and_slide()

func _on_hitbox_body_entered(body):
	if body.is_in_group("player") and not is_attacking:
		if body.has_method("take_damage"):
			body.take_damage(damage)
			is_attacking = true
			sprite.play("attack")
			await get_tree().create_timer(0.5).timeout
			is_attacking = false
			sprite.play("run")

func _on_animation_finished():
	if sprite.animation == "attack":
		is_attacking = false
		sprite.play("run")

func take_damage(amount):
	health -= amount
	health = clamp(health, 0, max_health)
	health_bar.value = health
	if health <= 0:
		die()
@export var exp_scene: PackedScene
@export var exp_drop_count = randi_range(1,2)

func die():
	for i in exp_drop_count:
		if randf() > 0.3:
			continue
		if exp_scene != null:
			var drop = exp_scene.instantiate()
			drop.global_position = global_position
			get_tree().current_scene.call_deferred("add_child", drop)
	call_deferred("queue_free")
