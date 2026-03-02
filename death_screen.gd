extends CanvasLayer

@onready var retry_sprite = $RetrySprite
@onready var wave_label = $WaveLabel

var blink_timer = 0.0

func _ready():
	visible = false

func show_death(wave: int):
	visible = true
	wave_label.text = "Llegaste a la oleada " + str(wave)
	$Sprite2D.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate:a", 1.0, 1.0)

func _process(delta):
	if not visible:
		return
	blink_timer += delta
	retry_sprite.modulate.a = 1.0 if fmod(blink_timer, 1.0) < 0.5 else 0.0
	if Input.is_action_just_pressed("ui_accept"):
		get_tree().reload_current_scene()
