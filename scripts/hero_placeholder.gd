class_name HeroPlaceholder
extends Node2D

const TILE_SIZE := Vector2(64.0, 32.0)

var hero_name: String = "Hero"
var damage_type: String = "?"

func _ready() -> void:
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(0.0, -TILE_SIZE.y / 2.0 - 6.0),
		Vector2(TILE_SIZE.x / 2.0 - 6.0, -6.0),
		Vector2(0.0, TILE_SIZE.y / 2.0 - 6.0),
		Vector2(-TILE_SIZE.x / 2.0 + 6.0, -6.0),
	])
	poly.color = Color(0.2, 0.4, 0.85, 0.92)
	add_child(poly)

	var lbl := Label.new()
	lbl.name = "NameLabel"
	lbl.text = hero_name[0].to_upper() if hero_name.length() > 0 else "?"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.position = Vector2(-20.0, -28.0)
	lbl.size = Vector2(40.0, 20.0)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	add_child(lbl)

func setup(p_name: String, p_damage_type: String) -> void:
	hero_name = p_name
	damage_type = p_damage_type
	var lbl := get_node_or_null("NameLabel") as Label
	if lbl:
		lbl.text = hero_name[0].to_upper() if hero_name.length() > 0 else "?"
