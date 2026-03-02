extends Node2D

var length = 1000.0
var color = Color(1, 0, 0, 1)
var width = 12.0
var damage = 1
var active = false

@onready var line = $Line2D

func _ready():
	line.width = width
	line.default_color = color
	line.add_point(Vector2(-length, 0))
	line.add_point(Vector2(length, 0))

func _physics_process(_delta):
	if not active:
		return
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var dir = Vector2(cos(global_rotation), sin(global_rotation))
	var to_player = player.global_position - global_position
	var dot = to_player.dot(dir)
	var cross = abs(to_player.x * dir.y - to_player.y * dir.x)
	if dot > -length and dot < length and cross < 20:
		player.take_damage(damage)
