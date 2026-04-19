class_name Projectile
extends Node2D

## Projectile à tête chercheuse.
## Ajouté à la scène racine (RunTest) par le héros qui tire.
## Appelle take_damage() sur la cible à l'impact — c'est là que le DamageNumber apparaît.

const SPEED      := 380.0   # pixels world/sec
const HIT_RADIUS := 12.0    # distance de déclenchement de l'impact

var _target:      EnemyBase = null
var _damage:      int       = 0
var _damage_type: int       = 0
var _color:       Color     = Color.WHITE

# Optional effect fields — set before setup() is called
var dot_dps: float = 0.0       # DoT damage per second to apply on hit
var dot_dur: float = 0.0       # DoT duration in seconds
var aoe_radius: float = 0.0    # if > 0: splash half-damage to nearby enemies
var chain_remaining: int = 0   # if > 0: bounce to nearest enemy after hit
var slow_chance: float = 0.0   # probability (0-1) to apply 50% slow for 1.5s on hit

func setup(target: EnemyBase, damage: int, damage_type: int, color: Color) -> void:
	_target      = target
	_damage      = damage
	_damage_type = damage_type
	_color       = color

func _process(delta: float) -> void:
	# La cible est morte avant l'impact → le projectile disparaît
	if not is_instance_valid(_target):
		queue_free()
		return

	var to_target := _target.global_position - global_position

	if to_target.length() <= HIT_RADIUS:
		_on_hit()
		queue_free()
		return

	global_position += to_target.normalized() * SPEED * delta

func _on_hit() -> void:
	if not is_instance_valid(_target):
		return
	_target.take_damage(_damage, _damage_type)
	if dot_dps > 0.0 and is_instance_valid(_target):
		_target.apply_dot(dot_dps, dot_dur, _damage_type)
	if slow_chance > 0.0 and randf() < slow_chance and is_instance_valid(_target):
		_target.apply_slow(0.5, 1.5)
	if aoe_radius > 0.0:
		_do_aoe()
	if chain_remaining > 0:
		_do_chain()

func _do_aoe() -> void:
	for enemy: EnemyBase in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy == _target:
			continue
		if global_position.distance_to(enemy.global_position) <= aoe_radius:
			enemy.take_damage(maxi(_damage >> 1, 1), _damage_type)

func _do_chain() -> void:
	var nearest: EnemyBase = null
	var nearest_dist := INF
	for enemy: EnemyBase in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy == _target:
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	if nearest == null:
		return
	var chain_proj := Projectile.new()
	chain_proj.z_index = 5
	get_tree().current_scene.add_child(chain_proj)
	chain_proj.global_position = global_position
	chain_proj.dot_dps = dot_dps
	chain_proj.dot_dur = dot_dur
	chain_proj.slow_chance = slow_chance
	chain_proj.chain_remaining = chain_remaining - 1
	chain_proj.setup(nearest, maxi(_damage >> 1, 1), _damage_type, _color)

func _draw() -> void:
	# Halo semi-transparent
	draw_circle(Vector2.ZERO, 8.0, Color(_color.r, _color.g, _color.b, 0.25))
	# Noyau solide
	draw_circle(Vector2.ZERO, 5.0, _color)
