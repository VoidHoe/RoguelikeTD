class_name HpBar
extends Node2D

## Barre de vie dessinée au-dessus du sprite ennemi.
## Ajoutée comme nœud enfant de l'ennemi avec z_index élevé.

const BAR_WIDTH  := 60.0
const BAR_HEIGHT := 8.0

var _current_hp: int = 1
var _max_hp:     int = 1

func update(current: int, maximum: int) -> void:
	_current_hp = current
	_max_hp     = maximum
	queue_redraw()

func _draw() -> void:
	if _current_hp >= _max_hp or _current_hp <= 0:
		return

	var hp_pct := float(_current_hp) / float(_max_hp)
	var bx     := -BAR_WIDTH * 0.5

	# Fond sombre
	draw_rect(Rect2(bx, 0.0, BAR_WIDTH, BAR_HEIGHT),
		Color(0.1, 0.1, 0.1, 0.85))

	# Remplissage — vert → jaune → rouge
	var fill: Color
	if hp_pct > 0.6:
		fill = Color(0.2,  0.88, 0.25)
	elif hp_pct > 0.3:
		fill = Color(0.95, 0.78, 0.1)
	else:
		fill = Color(0.92, 0.18, 0.18)
	draw_rect(Rect2(bx, 0.0, BAR_WIDTH * hp_pct, BAR_HEIGHT), fill)

	# Contour
	draw_rect(Rect2(bx, 0.0, BAR_WIDTH, BAR_HEIGHT),
		Color(0.0, 0.0, 0.0, 0.9), false, 1.2)
