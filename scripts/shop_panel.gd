class_name ShopPanel
extends CanvasLayer

## Emitted when the player buys a hero. run_test enters placement mode on receipt.
signal hero_bought(hero_data: Dictionary)

var _heroes: Array[Dictionary] = []
var _gold: int = 0
var _wave_active: bool = false

@onready var _content: VBoxContainer = $Root/Panel/Margin/VBox/Content

func _ready() -> void:
	visible = false

## Add a hero to the shop. Heroes stay purchasable indefinitely (multiple copies allowed).
func add_hero(hero_data: Dictionary) -> void:
	_heroes.append(hero_data)
	visible = true
	_rebuild()

## Call whenever gold or wave state changes so buy buttons stay up to date.
func refresh(gold: int, wave_active: bool) -> void:
	_gold = gold
	_wave_active = wave_active
	_rebuild()

func _rebuild() -> void:
	if _content == null:
		return
	for child in _content.get_children():
		child.queue_free()

	for hero_data in _heroes:
		var btn := Button.new()
		btn.text = "%s  —  %d or" % [hero_data.name, hero_data.cost]
		btn.disabled = _gold < hero_data.cost or _wave_active
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var captured: Dictionary = hero_data
		btn.pressed.connect(func() -> void:
			hero_bought.emit(captured)
		)
		_content.add_child(btn)
