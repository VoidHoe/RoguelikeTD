class_name PlayerBase
extends Node

@export var max_hp: int = 20
@export var starting_gold: int = 80

var current_hp: int = 0
var gold: int = 0
var _spectral_shields: int = 0   # Bouclier spectral : absorbe 1 coup fatal

signal hp_changed(current: int, maximum: int)
signal gold_changed(amount: int)
signal game_over

func _ready() -> void:
	current_hp = max_hp
	gold = starting_gold

func take_damage(amount: int) -> void:
	current_hp -= amount
	# Bouclier spectral : si ce coup tuerait la base, absorbe le coup et s'épuise
	if current_hp <= 0 and _spectral_shields > 0:
		current_hp = 1
		_spectral_shields -= 1
	if current_hp < 0:
		current_hp = 0
	hp_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		game_over.emit()

## Ajoute un Bouclier spectral (absorbera le prochain coup fatal).
func add_spectral_shield(amount: int = 1) -> void:
	_spectral_shields += amount

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

func heal(amount: int) -> void:
	current_hp = min(current_hp + amount, max_hp)
	hp_changed.emit(current_hp, max_hp)
