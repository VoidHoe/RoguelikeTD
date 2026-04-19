class_name HeroPlaceholder
extends Node2D

var hero_name: String = "Hero"
var damage_type: String = "?"

func _ready() -> void:
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = load("res://assets/Characters/Human/Human_0_Idle0.png")
	sprite.centered = true
	sprite.offset = Vector2(0, 0)
	add_child(sprite)

func setup(p_name: String, p_damage_type: String, texture_path: String = "") -> void:
	hero_name = p_name
	damage_type = p_damage_type
	var sprite := get_node_or_null("Sprite") as Sprite2D
	if sprite and texture_path != "":
		sprite.texture = load(texture_path)
