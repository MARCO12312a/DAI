extends Area2D

@export var b_laser_cross_scene: PackedScene
@export var b_laser_walls_scene: PackedScene
@export var b_trident_scene: PackedScene
@export var b_skull_scene: PackedScene

@export var b_trident_count = 4
@export var b_trident_spacing = 60.0
@export var b_trident_delay = 1.5

@export var b_laser_wall_speed = 100.0
@export var b_laser_wall_stop = 60.0

@export var b_laser_cross_duration = 4.0
@export var b_laser_rotate_speed = -0.5

@export var b_dash_speed = 400.0
@export var b_dash_trail_interval = 0.02
@export var b_dash_telegraph_time = 0.6

@export var b_skull_count = 1
@export var b_skull_burst_duration = 3.0
@export var b_skull_interval = 0.3

@export var b_move_speed = 800.0
@export var b_wait_time = 1.5
@export var b_max_health = 100

var health = 100
var is_moving = false
var is_attacking = false
var second_phase = false
var phase_speed = 1.0

enum Attack { LASER_CROSS, TRIDENTS, LASER_WALLS, DASH, SKULLS }

@onready var health_bar = $"../CanvasLayer/BossHealthBar"

func _ready():
	health = b_max_health
	health_bar.max_value = b_max_health
	health_bar.value = health
	health_bar.visible = false
	await get_tree().process_frame
	health_bar.visible = true  
	body_entered.connect(_on_body_entered)
	_next_move()

func _process(_delta):
	if health <= b_max_health / 2.0 and not second_phase:
		second_phase = true
		phase_speed = 1.5
		print("Segunda fase activada")

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(1)

func take_damage(amount):
	health -= amount	
	if health_bar != null:
		health_bar.value = health
	if health <= 0:
		die()

func die():
	if health_bar != null:
		health_bar.visible = false
	queue_free()

# ── MOVIMIENTO ──────────────────────────────────────────────────────

func _next_move():
	var points = get_tree().get_nodes_in_group("boss_points")
	if points.is_empty():
		return
	var target = points[randi() % points.size()]
	is_moving = true
	var tween = create_tween()
	tween.tween_interval(b_wait_time)
	tween.tween_property(self, "global_position", target.global_position,
		global_position.distance_to(target.global_position) / b_move_speed)
	tween.tween_callback(func():
		is_moving = false
		_on_arrived()
	)

func _on_arrived():
	if second_phase:
		var attacks = _pick_attacks(2)
		await _run_attacks_parallel(attacks)
	else:
		await launch_attack(_pick_attacks(1)[0])
	_next_move()

func _run_attacks_parallel(attacks: Array) -> void:
	var finished = 0
	var total = attacks.size()
	for atk in attacks:
		_run_single(atk, func():
			finished += 1
		)
	while finished < total:
		await get_tree().process_frame

func _run_single(attack, callback: Callable) -> void:
	await launch_attack(attack)
	callback.call()

func _pick_attacks(count: int) -> Array:
	var pool = [Attack.LASER_CROSS, Attack.TRIDENTS, Attack.LASER_WALLS, Attack.DASH, Attack.SKULLS]
	pool.shuffle()
	var chosen = []
	for atk in pool:
		if chosen.size() >= count:
			break
		if atk in chosen:
			continue
		if Attack.LASER_WALLS in chosen:
			continue
		if atk == Attack.LASER_WALLS and chosen.size() > 0:
			continue
		chosen.append(atk)
	return chosen

func launch_attack(attack) -> void:
	match attack:
		Attack.LASER_CROSS:
			await attack_laser_cross()
		#Attack.TRIDENTS:
			#await attack_tridents()
		Attack.LASER_WALLS:
			await attack_laser_walls()
		Attack.DASH:
			await attack_dash()
		Attack.SKULLS:
			await attack_skulls()

# ── MOVIMIENTO AL CENTRO ─────────────────────────────────────────────

func _move_to_center() -> void:
	var center = get_tree().get_nodes_in_group("boss_points").filter(
		func(p): return p.name == "Centro"
	)
	if center.is_empty():
		return
	var tween = create_tween()
	tween.tween_property(self, "global_position", center[0].global_position,
		global_position.distance_to(center[0].global_position) / b_move_speed)
	await tween.finished

# ── ATAQUE 1: LASER EN CRUZ ──────────────────────────────────────────

func attack_laser_cross():
	await _move_to_center()
	if b_laser_cross_scene == null:
		push_error("b_laser_cross_scene no asignado")
		return

	var lasers = []
	for i in 4:
		var laser = b_laser_cross_scene.instantiate()
		get_tree().current_scene.add_child(laser)
		laser.global_position = global_position
		laser.rotation = deg_to_rad(i * 90.0)
		laser.active = true
		lasers.append(laser)

	var elapsed = 0.0
	var duration = b_laser_cross_duration
	var rot_speed = b_laser_rotate_speed * phase_speed
	while elapsed < duration:
		var delta = get_process_delta_time()
		elapsed += delta
		for laser in lasers:
			if is_instance_valid(laser):
				laser.rotation += rot_speed * delta
		await get_tree().process_frame

	for laser in lasers:
		if is_instance_valid(laser):
			laser.queue_free()

# ── ATAQUE 2: TRIDENTES ──────────────────────────────────────────────

#func attack_tridents():
	#print("iniciando tridentes, scene: ", b_trident_scene)
	#if b_trident_scene == null:
		#push_error("b_trident_scene no asignado")
		#return
	#var speed_mult = phase_speed
	#var left_x = -573.0
#
	#var y_positions = []
	#for i in b_trident_count:
		#var offset = (i - (b_trident_count - 1) / 2.0) * b_trident_spacing
		#y_positions.append(270.0 + offset)
#
	#for _rafaga in 3:
		#for y in y_positions:
			#var t = b_trident_scene.instantiate()
			#get_tree().current_scene.add_child(t)
			#t.global_position = Vector2(left_x, y)
			#t.direction = Vector2.RIGHT
			#t.speed = 300.0 * speed_mult
			#print("tridente en: ", t.global_position, " dir: ", t.direction)
		#await get_tree().create_timer(b_trident_delay / speed_mult).timeout
#
	#await get_tree().create_timer(1.5).timeout

# ── ATAQUE 3: LASER WALLS ────────────────────────────────────────────

func attack_laser_walls():
	await _move_to_center()
	if b_laser_walls_scene == null:
		push_error("b_laser_walls_scene no asignado")
		return

	var left_laser = b_laser_walls_scene.instantiate()
	get_tree().current_scene.add_child(left_laser)
	left_laser.global_position = Vector2(-573, global_position.y)
	left_laser.direction = 1.0
	left_laser.speed = b_laser_wall_speed * phase_speed
	left_laser.stop_x = -b_laser_wall_stop
	left_laser.active = true

	var right_laser = b_laser_walls_scene.instantiate()
	get_tree().current_scene.add_child(right_laser)
	right_laser.global_position = Vector2(573, global_position.y)
	right_laser.direction = -1.0
	right_laser.speed = b_laser_wall_speed * phase_speed
	right_laser.stop_x = b_laser_wall_stop
	right_laser.active = true

	while not (left_laser.stopped and right_laser.stopped):
		var player = get_tree().get_first_node_in_group("player")
		if player != null:
			var px = player.global_position.x
			var lx = left_laser.global_position.x
			var rx = right_laser.global_position.x
			if px < lx or px > rx:
				player.take_damage(1)
		await get_tree().process_frame

	await get_tree().create_timer(0.5).timeout

	var slam_target = Vector2(global_position.x, 292.0)
	var tween = create_tween()
	tween.tween_property(self, "global_position", slam_target, 0.2 / phase_speed)
	await tween.finished

	await get_tree().create_timer(0.8).timeout

	left_laser.queue_free()
	right_laser.queue_free()

# ── ATAQUE 4: DASH ───────────────────────────────────────────────────

func attack_dash():
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var dash_count = 1 if not second_phase else 3

	for i in dash_count:
		await get_tree().create_timer(b_dash_telegraph_time).timeout

		player = get_tree().get_first_node_in_group("player")
		if player == null:
			return

		var target_pos = player.global_position
		var distance = global_position.distance_to(target_pos)
		var duration = distance / (b_dash_speed * phase_speed)

		var tween = create_tween()
		tween.tween_property(self, "global_position", target_pos, duration)

		var elapsed = 0.0
		var trail_t = 0.0
		while elapsed < duration:
			var delta = get_process_delta_time()
			elapsed += delta
			trail_t -= delta
			if trail_t <= 0:
				trail_t = b_dash_trail_interval
				spawn_boss_trail()
			await get_tree().process_frame

		await get_tree().create_timer(0.3).timeout

func spawn_boss_trail():
	var ghost = $AnimatedSprite2D.duplicate()
	ghost.global_position = $AnimatedSprite2D.global_position
	ghost.modulate = Color(0.5, 0.2, 1.0, 0.7)
	get_tree().current_scene.add_child(ghost)
	var tween = create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): ghost.queue_free())

# ── ATAQUE 5: CALAVERAS ──────────────────────────────────────────────

func attack_skulls():
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var duration = b_skull_burst_duration * (1.5 if second_phase else 1.0)
	var elapsed = 0.0

	while elapsed < duration:
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			break

		for i in b_skull_count:
			if b_skull_scene == null:
				continue
			var skull = b_skull_scene.instantiate()
			get_tree().current_scene.add_child(skull)
			skull.global_position = global_position

			var base_dir = (player.global_position - global_position).normalized()
			var angle_offset = deg_to_rad(randf_range(-45.0, 45.0))
			var dir = base_dir.rotated(angle_offset)
			skull.direction = dir

		var interval = b_skull_interval / phase_speed
		await get_tree().create_timer(interval).timeout
		elapsed += interval
