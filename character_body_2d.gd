extends CharacterBody2D

@export var pistol_scene: PackedScene
@export var shotgun_scene: PackedScene

var current_weapon: Node2D = null

@export var max_health = 3
var health = 3

@export var dodged_scene: PackedScene

@export var knockback_force = 200.0
@export var invul_time = 1.0

@export var dodge_chance: float = 0.2

var invulnerable = false
var is_hurt = false

@onready var damage_overlay = $"../CanvasLayer/DamageOverlay"
@onready var death_overlay = $"../CanvasLayer/DeathOverlay"
@onready var heartbeat_low = $"../CanvasLayer/HeartbeatLow"
@onready var heartbeat_high = $"../CanvasLayer/HeartbeatHigh"
@onready var flatline = $"../CanvasLayer/FlatlineSound"

@export var dash_trail_interval = 0.03
@export var dash_trail_lifetime = 0.2
var trail_timer = 0.0

@export var wall_lock_time = 0.15
var wall_lock_timer = 0.0

@export var wall_slide_speed = 80.0

@export var fire_rate = 0.1
@export var bullet_damage = 1
@export var bullet_scene: PackedScene

var fire_timer = 0.0

enum State { NORMAL, DASH, DEAD, HEALING }
var state = State.NORMAL

@onready var wall_left = $WallLeft
@onready var wall_right = $WallRight

@export var drop_time = 0.2
var drop_timer = 0.0

@export var max_speed = 120.0

@onready var weapon_pivot = $WeaponPivot
var weapon_sprite: Sprite2D = null

@export var wall_jump_force = -300.0
@export var wall_push_force = 100.0

@export var gravity = 1200.0
@export var jump_force = -300.0

@export var dash_speed = 320.0
@export var dash_time = 0.27
@export var double_tap_time = 0.25

@onready var sprite = $AnimatedSprite2D

@export var coyote_time = 0.12
var coyote_timer = 0.0

var jumps_left = 1
var dash_timer = 0.0
var dash_direction = 0
var last_tap_left = -1.0
var last_tap_right = -1.0

@export var fast_fall_speed = 950.0
@export var fast_fall_gravity = 3000.0
var fast_falling = false

# ── SISTEMA DE CURACIÓN ──────────────────────────────────────────────
@export var heal_speed_penalty = 0.3       # multiplicador de velocidad al curar (30%)
@export var heal_duration = 2.0            # segundos que tarda en curar
@export var exp_required = 5               # exp necesaria para poder curar
@export var heal_sprite_scene: PackedScene # escena del botiquin

@onready var heal_bar = $"../CanvasLayer/HealBar"  # TextureProgressBar circular
@onready var camera = $Camera2D   # ajusta la ruta a tu cámara

var exp_current = 0
var is_healing = false
var heal_timer = 0.0
var heal_weapon_node: Node2D = null
var base_zoom: Vector2 = Vector2(1, 1)

func _ready():
	weapon_pivot.visible = false
	health = max_health
	add_to_group("player")
	equip_weapon(pistol_scene)
	if camera:
		base_zoom = camera.zoom
	if heal_bar:
		heal_bar.max_value = exp_required
		heal_bar.value = 0

func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		get_tree().paused = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		get_tree().paused = false

func _physics_process(delta):
	var is_running = abs(velocity.x) > 0 and is_on_floor()
	if is_running:
		if not $AudioRun.playing:
			$AudioRun.play()
	else:
		$AudioRun.stop()

	if state == State.DEAD:
		velocity.y += gravity * delta
		move_and_slide()
		return

	handle_weapon_switch()
	handle_shooting(delta)
	handle_heal_input(delta)

	if is_on_floor():
		fast_falling = false

	if wall_lock_timer > 0:
		wall_lock_timer -= delta
	if drop_timer > 0:
		drop_timer -= delta

	if state == State.NORMAL or state == State.HEALING:
		normal_state(delta)
	elif state == State.DASH:
		dash_state(delta)

	update_weapon()
	move_and_slide()

	if drop_timer <= 0:
		set_collision_mask_value(5, true)

# ── CURACIÓN ─────────────────────────────────────────────────────────

func add_exp(amount: int):
	exp_current = min(exp_current + amount, exp_required)
	if heal_bar:
		heal_bar.value = exp_current

func handle_heal_input(delta):
	if exp_current < exp_required:
		return
	if health >= max_health:
		return

	if Input.is_action_pressed("Q") and state != State.DEAD and state != State.DASH:
		if not is_healing:
			start_healing()
		heal_timer += delta
		# Actualiza zoom suavemente
		if camera:
			camera.zoom = camera.zoom.lerp(base_zoom * 1.3, delta * 2.0)
		if heal_timer >= heal_duration:
			finish_healing()
	else:
		if is_healing:
			cancel_healing()

func start_healing():
	is_healing = true
	heal_timer = 0.0
	# Muestra botiquin
	if heal_sprite_scene != null and heal_weapon_node == null:
		heal_weapon_node = heal_sprite_scene.instantiate()
		weapon_pivot.add_child(heal_weapon_node)
	weapon_pivot.visible = true

func finish_healing():
	is_healing = false
	heal_timer = 0.0
	exp_current = 0
	health = min(health + 1, max_health)
	update_damage_effects()
	if heal_bar:
		heal_bar.value = 0
	# Zoom vuelve a la normalidad
	if camera:
		var tween = create_tween()
		tween.tween_property(camera, "zoom", base_zoom, 0.5)
	cancel_healing()

func cancel_healing():
	is_healing = false
	if heal_weapon_node != null:
		heal_weapon_node.queue_free()
		heal_weapon_node = null
	weapon_pivot.visible = false
	# Zoom vuelve a la normalidad
	if camera:
		var tween = create_tween()
		tween.tween_property(camera, "zoom", base_zoom, 0.3)

# ── MOVIMIENTO ───────────────────────────────────────────────────────

func normal_state(delta):
	var input_dir = Input.get_axis("A", "D")
	var current_max_speed = max_speed * (heal_speed_penalty if is_healing else 1.0)

	if Input.is_action_pressed("S") and is_on_floor() and drop_timer <= 0:
		drop_timer = drop_time
		set_collision_mask_value(5, false)

	if wall_lock_timer <= 0:
		if input_dir != 0:
			velocity.x = input_dir * current_max_speed
			sprite.flip_h = input_dir < 0
		else:
			velocity.x = 0

	if is_on_floor():
		coyote_timer = coyote_time
		jumps_left = 1
	else:
		coyote_timer -= delta
		velocity.y += gravity * delta

	if not is_on_floor() \
	and (wall_left.is_colliding() or wall_right.is_colliding()) \
	and velocity.y > 0 \
	and wall_lock_timer <= 0:
		if velocity.y > wall_slide_speed:
			velocity.y = wall_slide_speed

	if not is_on_floor() \
	and velocity.y > 0 \
	and Input.is_action_pressed("S") \
	and Input.is_action_pressed("JUMP"):
		fast_falling = true

	if fast_falling:
		if velocity.y < 0:
			velocity.y = 0
		velocity.y += fast_fall_gravity * delta
		if velocity.y > fast_fall_speed:
			velocity.y = fast_fall_speed

	if Input.is_action_just_pressed("JUMP"):
		if is_on_floor() or coyote_timer > 0:
			velocity.y = jump_force
			coyote_timer = 0
		elif wall_left.is_colliding() and not is_on_floor():
			velocity.y = jump_force
			velocity.x = wall_push_force
			wall_lock_timer = wall_lock_time
		elif wall_right.is_colliding() and not is_on_floor():
			velocity.y = jump_force
			velocity.x = -wall_push_force
			wall_lock_timer = wall_lock_time
		elif jumps_left > 0:
			velocity.y = jump_force
			jumps_left -= 1

	if Input.is_action_just_released("JUMP") and velocity.y < 0:
		velocity.y *= 0.4

	if is_hurt:
		return
	if not is_on_floor():
		if sprite.animation != "Jump":
			sprite.play("Jump")
	else:
		if abs(velocity.x) > 1:
			if sprite.animation != "Run":
				sprite.play("Run")
		else:
			if sprite.animation != "Idle":
				sprite.play("Idle")

	if not is_healing:
		check_dash_input()

func dash_state(delta):
	dash_timer -= delta
	velocity.x = dash_direction * dash_speed

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		jumps_left = 1

	if not is_on_floor() and Input.is_action_pressed("S"):
		if velocity.y < 0:
			velocity.y = 0
		velocity.y += fast_fall_gravity * delta
		if velocity.y > fast_fall_speed:
			velocity.y = fast_fall_speed

	if Input.is_action_just_pressed("JUMP"):
		if is_on_floor():
			velocity.y = jump_force
		elif jumps_left > 0:
			velocity.y = jump_force
			jumps_left -= 1

	trail_timer -= delta
	if trail_timer <= 0:
		trail_timer = dash_trail_interval
		spawn_dash_trail()

	if dash_timer <= 0:
		state = State.NORMAL

func check_dash_input():
	var time_now = Time.get_ticks_msec() / 1000.0
	if Input.is_action_just_pressed("A"):
		if time_now - last_tap_left <= double_tap_time:
			start_dash(-1)
		last_tap_left = time_now
	if Input.is_action_just_pressed("D"):
		if time_now - last_tap_right <= double_tap_time:
			start_dash(1)
		last_tap_right = time_now

func start_dash(direction):
	if is_healing:
		cancel_healing()
	trail_timer = 0.0
	state = State.DASH
	dash_timer = dash_time
	dash_direction = direction

func spawn_dash_trail():
	var ghost = sprite.duplicate()
	ghost.global_position = sprite.global_position
	ghost.global_rotation = sprite.global_rotation
	ghost.scale = sprite.global_scale
	ghost.modulate = Color(1, 1, 1, 0.6)
	get_tree().current_scene.add_child(ghost)
	var tween = create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, dash_trail_lifetime)
	tween.tween_callback(func(): ghost.queue_free())

func update_weapon():
	if weapon_pivot == null:
		return
	var mouse_pos = get_global_mouse_position()
	weapon_pivot.look_at(mouse_pos)
	weapon_pivot.visible = Input.is_action_pressed("click") or is_healing
	if mouse_pos.x < global_position.x:
		sprite.flip_h = true
		if weapon_sprite != null:
			weapon_sprite.flip_v = true
	else:
		sprite.flip_h = false
		if weapon_sprite != null:
			weapon_sprite.flip_v = false

func handle_weapon_switch():
	if is_healing:
		return
	if Input.is_action_just_pressed("1"):
		equip_weapon(pistol_scene)
	elif Input.is_action_just_pressed("2"):
		equip_weapon(shotgun_scene)

func equip_weapon(scene: PackedScene):
	if scene == null:
		return
	if current_weapon != null:
		current_weapon.queue_free()
	current_weapon = scene.instantiate()
	weapon_pivot.add_child(current_weapon)
	weapon_sprite = current_weapon.get_node("WeaponSprite")

func handle_shooting(_delta):
	if is_healing:
		return
	if Input.is_action_pressed("click"):
		weapon_pivot.visible = true
		if current_weapon != null:
			current_weapon.try_shoot()
	else:
		weapon_pivot.visible = false

# ── DAÑO Y MUERTE ────────────────────────────────────────────────────

func take_damage(amount):
	if invulnerable or state == State.DEAD or state == State.DASH:
		return
	if is_healing:
		cancel_healing()
	if randf() < dodge_chance:
		dodge()
		return
	health -= amount
	is_hurt = true
	sprite.play("Hurt")
	update_damage_effects()
	start_invulnerability()
	if health != 0:
		await sprite.animation_finished
	is_hurt = false
	if health <= 0:
		die()

func update_damage_effects():
	if damage_overlay == null:
		return
	var target_alpha := 0.0
	heartbeat_low.stop()
	heartbeat_high.stop()
	match health:
		3:
			target_alpha = 0.0
		2:
			target_alpha = 0.25
		1:
			target_alpha = 0.5
		_:
			target_alpha = 0.7
	var tween = create_tween()
	tween.tween_property(damage_overlay, "modulate:a", target_alpha, 0.3)
	if health == 3:
		damage_overlay.modulate.a = 0.0
	elif health == 2:
		damage_overlay.modulate.a = 0.3
		heartbeat_low.volume_db = -15
		heartbeat_low.play()
	elif health == 1:
		damage_overlay.modulate.a = 0.6
		heartbeat_high.volume_db = -5
		heartbeat_high.play()

var is_dead: bool = false

func die():
	is_dead = true
	state = State.DEAD
	if current_weapon != null:
		current_weapon.visible = false
	$AudioRun.stop()
	invulnerable = true
	velocity.x = 0
	heartbeat_low.stop()
	heartbeat_high.stop()
	set_collision_layer(0)
	remove_from_group("player")
	flatline.play()
	var tween = create_tween()
	tween.tween_property(death_overlay, "modulate:a", 1.0, 0.5)
	await tween.finished
	var death_screen = get_tree().get_first_node_in_group("death_screen")
	if death_screen:
		var wave_manager = get_tree().get_first_node_in_group("wave_manager")
		var wave = wave_manager.current_wave if wave_manager else 0
		death_screen.show_death(wave)

func dodge():
	$AudioDodge.play()
	start_invulnerability()
	show_dodged_text()
	await get_tree().create_timer(0.5).timeout

func show_dodged_text():
	var d = dodged_scene.instantiate()
	get_parent().add_child(d)
	d.global_position = global_position

func start_invulnerability():
	if health != 0:
		invulnerable = true
		modulate = Color(1, 1, 1, 0.5)
		await get_tree().create_timer(invul_time).timeout
		modulate = Color(1, 1, 1, 1)
		invulnerable = false
