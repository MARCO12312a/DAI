extends Node2D

@onready var play_button = $PlayBtn
@onready var background = $Sprite2D

func _process(_delta):
	if Input.is_action_just_pressed("click"):
		var mouse = get_global_mouse_position()
		if _is_hovering(mouse):
			start_game()

func _is_hovering(mouse: Vector2) -> bool:
	var size = play_button.texture.get_size() * play_button.scale
	var rect = Rect2(play_button.global_position - size / 2, size)
	return rect.has_point(mouse)

func start_game():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.5)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://game.tscn")
	)
	
