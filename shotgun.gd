
extends Node2D

@onready var weapon_sprite = $WeaponSprite
@export var fire_rate = 0.6
@export var bullet_damage = 1
@export var bullet_scene: PackedScene
@export var pellet_count = 6        # cantidad de balas
@export var spread_angle = 20.0     # dispersión en grados

var fire_timer = 0.0


func _process(delta):
	fire_timer -= delta
	var mouse_pos = get_global_mouse_position()
	if mouse_pos.x < global_position.x:
		weapon_sprite.flip_v = true
		weapon_sprite.flip_h = false
	else:
		weapon_sprite.flip_v = false
		weapon_sprite.flip_h = false

func try_shoot():
	if fire_timer <= 0:
		fire_timer = fire_rate
		shoot()

func shoot():
	$AudioStreamPlayer2D.play()
	if bullet_scene == null:
		return
	var base_dir = (get_global_mouse_position() - global_position).normalized()
	var base_angle = base_dir.angle()

	for i in pellet_count:
		var offset = randf_range(-spread_angle / 2.0, spread_angle / 2.0)
		var angle = base_angle + deg_to_rad(offset)
		var dir = Vector2(cos(angle), sin(angle))

		var bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = global_position + dir * 20
		bullet.rotation = angle
		bullet.direction = dir
		bullet.damage = bullet_damage
