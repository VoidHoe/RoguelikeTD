extends Node2D

@onready var iso_map: IsometricMap = $IsometricMap
@onready var hero_board: HeroBoard = $HeroBoard
@onready var hud_label: Label = $HUD/VBoxContainer/PlacedLabel

var _placed_heroes: Dictionary = {}  # Vector2i -> HeroPlaceholder
var _slot_map: Dictionary = {}  # Vector2i -> PlacementSlot

func _ready() -> void:
	for slot_pos: Vector2i in iso_map.get_slot_positions():
		var slot := PlacementSlot.new()
		slot.grid_position = slot_pos
		add_child(slot)
		hero_board.register_slot(slot)
		_slot_map[slot_pos] = slot

	iso_map.tile_clicked.connect(_on_tile_clicked)
	_update_hud()

func _on_tile_clicked(grid_pos: Vector2i, tile_type: IsometricMap.TileType) -> void:
	if tile_type != IsometricMap.TileType.SLOT:
		return

	var target_slot: PlacementSlot = _slot_map.get(grid_pos, null)
	if target_slot == null:
		return

	if target_slot.is_occupied:
		var hero := _placed_heroes.get(grid_pos) as HeroPlaceholder
		if hero:
			hero.queue_free()
			_placed_heroes.erase(grid_pos)
		hero_board.remove_hero_at(target_slot)
	else:
		var hero: HeroPlaceholder = preload("res://scenes/components/hero_placeholder.tscn").instantiate()
		hero.setup("Hero", "?")
		hero.position = iso_map.grid_to_screen(grid_pos)
		hero.z_index = grid_pos.x + grid_pos.y + 1
		iso_map.add_child(hero)
		_placed_heroes[grid_pos] = hero
		hero_board.place_hero_at(target_slot, hero)

	_update_hud()

func _update_hud() -> void:
	var total := hero_board.get_slot_count()
	var placed := hero_board.get_occupied_slots().size()
	hud_label.text = "Placed: %d / %d slots" % [placed, total]
