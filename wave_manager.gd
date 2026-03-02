extends Node

@export var witch_scene: PackedScene
@export var crawler_scene: PackedScene
@export var boss_scene: PackedScene

@onready var wave_label = $"../CanvasLayer/WaveLabel"

@export var rest_time = 5.0
@export var spawn_interval = 1.5
@export var base_crawler_speed = 150.0

var current_wave = 0
var enemies_alive = 0

func _ready():
	await get_tree().create_timer(1.0).timeout
	start_next_wave()

func start_next_wave():
	current_wave += 1
	print("Oleada: ", current_wave)
	show_wave_text()

	if current_wave % 5 == 0:
		await spawn_boss_wave()
	else:
		await spawn_wave()

	while enemies_alive > 0:
		await get_tree().process_frame

	await get_tree().create_timer(rest_time).timeout
	start_next_wave()

# ── OLEADA NORMAL CON SPAWN ALEATORIO MEZCLADO ───────────────────────

func spawn_wave():
	var speed_scale = 1.0 + (current_wave - 1) * 0.08
	var cooldown_scale = max(0.4, 1.0 - (current_wave - 1) * 0.06)
	var enemy_count = 7 + int(current_wave * 0.8)

	var spawn_list = []

	if current_wave <= 2:
		for i in enemy_count:
			spawn_list.append({
				"scene": crawler_scene,
				"stats": { "speed": base_crawler_speed * speed_scale }
			})
	elif current_wave <= 4:
		for i in int(enemy_count * 0.6):
			spawn_list.append({
				"scene": crawler_scene,
				"stats": { "speed": base_crawler_speed * speed_scale }
			})
		for i in int(enemy_count * 0.4):
			spawn_list.append({
				"scene": witch_scene,
				"stats": {
					"teleport_cooldown": 3.0 * cooldown_scale,
					"shoot_cooldown": 1.5 * cooldown_scale
				}
			})
	else:
		for i in int(enemy_count * 0.5):
			spawn_list.append({
				"scene": crawler_scene,
				"stats": { "speed": base_crawler_speed * speed_scale }
			})
		for i in int(enemy_count * 0.5):
			spawn_list.append({
				"scene": witch_scene,
				"stats": {
					"teleport_cooldown": 3.0 * cooldown_scale,
					"shoot_cooldown": 1.5 * cooldown_scale
				}
			})

	spawn_list.shuffle()

	for entry in spawn_list:
		spawn_enemy(entry.scene, entry.stats)
		await get_tree().create_timer(spawn_interval).timeout

# ── OLEADA DE JEFE ────────────────────────────────────────────────────

func spawn_boss_wave():
	@warning_ignore("integer_division")
	var boss_tier = current_wave / 5
	var scale = 1.0 + (boss_tier - 1) * 0.3

	if boss_scene != null:
		var boss = boss_scene.instantiate()
		get_tree().current_scene.add_child(boss)
		boss.b_max_health = int(100 * scale)
		boss.b_dash_speed *= scale
		boss.b_move_speed *= scale
		enemies_alive += 1
		boss.tree_exited.connect(func(): enemies_alive -= 1)

	# A partir de ronda 10 spawnea enemigos adicionales más débiles
	if current_wave >= 10:
		var speed_scale = 1.0 + (current_wave - 1) * 0.08
		var cooldown_scale = max(0.4, 1.0 - (current_wave - 1) * 0.06)
		var extra_count = 2 + int((current_wave - 10) * 0.5)

		var extra_list = []
		for i in extra_count:
			if randi() % 2 == 0:
				extra_list.append({
					"scene": crawler_scene,
					"stats": { "speed": base_crawler_speed * speed_scale * 0.7 }
				})
			else:
				extra_list.append({
					"scene": witch_scene,
					"stats": {
						"teleport_cooldown": 3.0 * cooldown_scale * 1.5,
						"shoot_cooldown": 1.5 * cooldown_scale * 1.5
					}
				})

		extra_list.shuffle()
		for entry in extra_list:
			await get_tree().create_timer(spawn_interval * 1.5).timeout
			spawn_enemy(entry.scene, entry.stats)

	await get_tree().process_frame

# ── SPAWN DE ENEMIGO ──────────────────────────────────────────────────

func spawn_enemy(scene: PackedScene, stats: Dictionary):
	if scene == null:
		return
	var enemy = scene.instantiate()
	var points = get_tree().get_nodes_in_group("spawn_points")
	if not points.is_empty():
		enemy.global_position = points[randi() % points.size()].global_position
	get_tree().current_scene.add_child(enemy)
	if stats.has("speed"):
		enemy.speed = stats.speed
	if stats.has("teleport_cooldown"):
		enemy.teleport_cooldown = stats.teleport_cooldown
	if stats.has("shoot_cooldown"):
		enemy.shoot_cooldown = stats.shoot_cooldown
	enemies_alive += 1
	enemy.tree_exited.connect(func(): enemies_alive -= 1)

func show_wave_text():
	print("--- OLEADA ", current_wave, " ---")
	if wave_label == null:
		return
	wave_label.text = "WAVE " + str(current_wave)
	wave_label.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(wave_label, "modulate:a", 0.0, 1.0)
