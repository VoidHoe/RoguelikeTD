extends GutTest

var pb: PlayerBase

func before_each() -> void:
	pb = PlayerBase.new()
	add_child_autofree(pb)

func test_starts_at_full_hp() -> void:
	assert_eq(pb.current_hp, pb.max_hp)

func test_take_damage_reduces_hp() -> void:
	pb.take_damage(5)
	assert_eq(pb.current_hp, pb.max_hp - 5)

func test_hp_clamps_at_zero() -> void:
	pb.take_damage(9999)
	assert_eq(pb.current_hp, 0)

func test_hp_changed_signal_emitted() -> void:
	watch_signals(pb)
	pb.take_damage(3)
	assert_signal_emitted(pb, "hp_changed")

func test_game_over_emitted_at_zero() -> void:
	watch_signals(pb)
	pb.take_damage(pb.max_hp)
	assert_signal_emitted(pb, "game_over")
