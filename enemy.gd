extends CharacterBody2D

@onready var sprite=$AnimatedSprite2D

@onready var health_bar = $HealthBar

@export var max_health: float = 30
@export var teleport_cooldown: float = 3.0
@export var shoot_cooldown: float = 1.5
@export var projectile_scene: PackedScene
@export var contact_damage: int = 1
@export var enemy_name: String = "Enemy"
var health: float
var player: Node2D
var teleport_timer: float = 0.0
var shoot_timer: float = 0.0
var mouse_over:= false

func _ready():
	health = max_health
	player = get_tree().get_first_node_in_group("player")
	health_bar.max_value=max_health
	health_bar.value=health

func _physics_process(delta):

	if player == null or player.is_dead:
		return

	teleport_timer -= delta
	shoot_timer -= delta

	look_at_player()

	if teleport_timer <= 0:
		teleport_in_camera_view()
		teleport_timer = teleport_cooldown


	if shoot_timer <= 0:
		shoot()
		shoot_timer = shoot_cooldown
	
	elif health/max_health <= 0.5:
		teleport_cooldown = 0.7
		shoot_cooldown = 0.6

func look_at_player():
	var dir_x = player.global_position.x - global_position.x
	$AnimatedSprite2D.flip_h = dir_x < 0


func shoot():

	if projectile_scene == null:
		return

	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	var dir = (player.global_position - global_position).normalized()

	projectile.global_position = global_position + dir * 20
	projectile.direction = dir

	if has_node("AudioShootEnemy"):
		$AudioShoot.play()


func teleport_in_camera_view():

	var canvas_transform = get_viewport().get_canvas_transform()
	var visible_rect = get_viewport().get_visible_rect()

	# Convertir rectángulo visible a coordenadas de mundo
	var top_left = canvas_transform.affine_inverse() * visible_rect.position
	var bottom_right = canvas_transform.affine_inverse() * (visible_rect.position + visible_rect.size)

	var left = top_left.x
	var top = top_left.y
	var right = bottom_right.x
	var bottom = bottom_right.y

	var margin = 80
	var attempts = 10

	while attempts > 0:

		var random_x = randf_range(left + margin, right - margin)
		var random_y = randf_range(top + margin, bottom - margin)

		var pos = Vector2(random_x, random_y)

		# evitar aparecer muy cerca del jugador
		if pos.distance_to(player.global_position) < 150:
			attempts -= 1
			continue

		global_position = pos
		return


func take_damage(amount):
	health -= amount
	health = clamp(health, 0, max_health)

	health_bar.value = health

	if health <= 0:
		die()

@export var exp_scene: PackedScene
@export var exp_drop_count = randi_range(3,5)

func die():
	for i in exp_drop_count:
		if randf() > 0.3:
			continue
		if exp_scene != null:
			var drop = exp_scene.instantiate()
			drop.global_position = global_position
			get_tree().current_scene.call_deferred("add_child", drop)
	call_deferred("queue_free")
