extends Node2D

func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(1, 0.5, 0, 0.8), false, 2.0)
