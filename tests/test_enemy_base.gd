extends GutTest

var enemy: EnemyBase
var waypoints: Array[Vector2]

func before_each() -> void:
	enemy = EnemyBase.new()
	add_child_autofree(enemy)
	waypoints = [Vector2(0, 0), Vector2(100, 0), Vector2(200, 0)]

func test_enemy_starts_at_full_hp() -> void:
	assert_eq(enemy.current_hp, enemy.max_hp)

func test_take_damage_reduces_hp() -> void:
	enemy.take_damage(30)
	assert_eq(enemy.current_hp, enemy.max_hp - 30)

func test_take_damage_clamps_at_zero() -> void:
	enemy.take_damage(9999)
	assert_eq(enemy.current_hp, 0)

func test_take_damage_to_zero_emits_died() -> void:
	watch_signals(enemy)
	enemy.take_damage(enemy.max_hp)
	assert_signal_emitted(enemy, "died")

func test_setup_positions_at_first_waypoint() -> void:
	enemy.setup(waypoints)
	assert_eq(enemy.position, waypoints[0])

func test_setup_starts_targeting_second_waypoint() -> void:
	enemy.setup(waypoints)
	assert_eq(enemy._current_wp_idx, 1)

func test_no_movement_before_setup() -> void:
	assert_false(enemy._moving)
