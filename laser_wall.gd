extends Node2D

var color = Color(1, 0, 0, 1)
var width = 12.0
var height = 2000.0
var speed = 100.0
var direction = 1.0
var stop_x = 0.0
var damage = 1
var active = false
var stopped = false

@onready var line = $Line2D

func _ready():
	line.width = width
	line.default_color = color
	line.add_point(Vector2(0, -height / 2))
	line.add_point(Vector2(0, height / 2))

func _physics_process(delta):
	if not active:
		return
	if direction > 0 and global_position.x >= stop_x:
		stopped = true
		return
	if direction < 0 and global_position.x <= stop_x:
		stopped = true
		return
	global_position.x += direction * speed * delta
