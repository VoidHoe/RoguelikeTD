class_name DamageNumber
extends Node2D

## Chiffre flottant apparu lors d'un hit ennemi.
## Instancié directement (pas de .tscn nécessaire).
## Couleur : orange = faiblesse  |  blanc = normal  |  bleu = résistance

const FONT_SIZE  := 20
const RISE_DIST  := 55.0   # pixels de montée en world space
const RISE_TIME  := 0.85   # durée de l'animation
const FADE_DELAY := 0.30   # délai avant de commencer à disparaître

var _text:  String = ""
var _color: Color  = Color.WHITE

func setup(amount: int, color: Color) -> void:
	_text  = str(amount)
	_color = color
	queue_redraw()

	var drift := randf_range(-12.0, 12.0)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - RISE_DIST,           RISE_TIME)
	tween.tween_property(self, "position:x", position.x + drift,                RISE_TIME)
	tween.tween_property(self, "modulate:a", 0.0, RISE_TIME - FADE_DELAY).set_delay(FADE_DELAY)
	tween.finished.connect(queue_free)

func _draw() -> void:
	var font := ThemeDB.fallback_font
	# Ombre portée (décalage +1/+1)
	draw_string(font, Vector2(1.0, 1.0), _text,
		HORIZONTAL_ALIGNMENT_CENTER, -1, FONT_SIZE, Color(0.0, 0.0, 0.0, 0.75))
	# Texte principal
	draw_string(font, Vector2.ZERO, _text,
		HORIZONTAL_ALIGNMENT_CENTER, -1, FONT_SIZE, _color)
