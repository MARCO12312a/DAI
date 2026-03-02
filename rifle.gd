extends Node2D

@export var fire_rate = 0.1
@export var bullet_damage = 1
@export var bullet_scene: PackedScene

var fire_timer = 0.0

@onready var weapon_sprite = $WeaponSprite

func _process(delta):
	fire_timer -= delta

func try_shoot():
	if fire_timer <= 0:
		fire_timer = fire_rate
		shoot()

func shoot():
	$AudioStreamPlayer2D.play()
	if bullet_scene == null:
		return
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	var dir = (get_global_mouse_position() - global_position).normalized()
	bullet.global_position = global_position + dir * 20
	bullet.rotation = dir.angle()
	bullet.direction = dir
	bullet.damage = bullet_damage
