class_name PlacementSlot
extends Node2D

var grid_position: Vector2i = Vector2i.ZERO
var is_occupied: bool = false
var _hero_node: Node = null

func place_hero(hero: Node) -> void:
	_hero_node = hero
	is_occupied = true

func remove_hero() -> void:
	_hero_node = null
	is_occupied = false

func get_hero() -> Node:
	return _hero_node
