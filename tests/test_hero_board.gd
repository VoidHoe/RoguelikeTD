extends GutTest

var slot: PlacementSlot
var board: HeroBoard
var fake_hero: Node

func before_each() -> void:
	slot = PlacementSlot.new()
	slot.grid_position = Vector2i(2, 3)
	board = HeroBoard.new()
	board.register_slot(slot)
	fake_hero = Node.new()
	add_child_autofree(slot)
	add_child_autofree(board)
	add_child_autofree(fake_hero)

func test_slot_starts_empty() -> void:
	assert_false(slot.is_occupied)

func test_slot_get_hero_returns_null_when_empty() -> void:
	assert_null(slot.get_hero())

func test_place_hero_sets_occupied() -> void:
	slot.place_hero(fake_hero)
	assert_true(slot.is_occupied)

func test_place_hero_stores_hero_ref() -> void:
	slot.place_hero(fake_hero)
	assert_eq(slot.get_hero(), fake_hero)

func test_remove_hero_clears_occupied() -> void:
	slot.place_hero(fake_hero)
	slot.remove_hero()
	assert_false(slot.is_occupied)

func test_remove_hero_clears_hero_ref() -> void:
	slot.place_hero(fake_hero)
	slot.remove_hero()
	assert_null(slot.get_hero())

func test_remove_hero_on_empty_slot_no_error() -> void:
	slot.remove_hero()
	assert_false(slot.is_occupied)

func test_board_has_one_slot_after_register() -> void:
	assert_eq(board.get_slot_count(), 1)

func test_get_empty_slots_returns_all_when_empty() -> void:
	assert_eq(board.get_empty_slots().size(), 1)

func test_get_occupied_slots_returns_empty_when_none_placed() -> void:
	assert_eq(board.get_occupied_slots().size(), 0)

func test_place_hero_at_slot_makes_slot_occupied() -> void:
	board.place_hero_at(slot, fake_hero)
	assert_true(slot.is_occupied)

func test_after_placing_empty_slots_decreases() -> void:
	board.place_hero_at(slot, fake_hero)
	assert_eq(board.get_empty_slots().size(), 0)

func test_after_placing_occupied_slots_increases() -> void:
	board.place_hero_at(slot, fake_hero)
	assert_eq(board.get_occupied_slots().size(), 1)

func test_remove_hero_at_slot_clears_occupied() -> void:
	board.place_hero_at(slot, fake_hero)
	board.remove_hero_at(slot)
	assert_false(slot.is_occupied)

func test_place_hero_at_already_occupied_slot_no_op() -> void:
	var hero2 := Node.new()
	add_child_autofree(hero2)
	board.place_hero_at(slot, fake_hero)
	board.place_hero_at(slot, hero2)
	assert_eq(slot.get_hero(), fake_hero)
