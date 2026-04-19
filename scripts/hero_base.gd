class_name HeroBase
extends Node2D

@export var hero_name: String = "Hero"
@export var cost: int = 50
@export var damage_type: DamageTypes.Type = DamageTypes.Type.PERCANT
@export var attack_damage: int = 20
@export var attack_radius: float = 150.0
@export var attack_speed: float = 1.0

var _cooldown: float = 0.0
var _waypoints: Array[Vector2] = []
var _coord_parent: Node2D = null   # IsometricMap — waypoints live in its local space

@onready var anim_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func setup(waypoints: Array[Vector2], coord_parent: Node2D = null) -> void:
	_waypoints = waypoints
	_coord_parent = coord_parent

func _ready() -> void:
	_cooldown = 1.0 / attack_speed

func _process(delta: float) -> void:
	_cooldown -= delta
	var target := _get_closest_enemy()

	if target == null:
		_face_nearest_waypoint()
		return

	var direction := (target.global_position - global_position).normalized()
	_play_anim("attack_" + _direction_name(direction))

	if _cooldown <= 0.0:
		target.take_damage(attack_damage, int(damage_type))
		_cooldown = 1.0 / attack_speed

func _get_closest_enemy() -> EnemyBase:
	var closest: EnemyBase = null
	var closest_dist := attack_radius
	for enemy: EnemyBase in get_tree().get_nodes_in_group("enemies"):
		var dist := global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest = enemy
			closest_dist = dist
	return closest

func _direction_name(dir: Vector2) -> String:
	var angle := fmod(dir.angle() * 180.0 / PI + 360.0, 360.0)
	var dirs := ["E", "SE", "S", "SW", "W", "NW", "N", "NE"]
	return dirs[int((angle + 22.5) / 45.0) % 8]

func _face_nearest_waypoint() -> void:
	if anim_sprite == null or _waypoints.size() < 2:
		_play_anim("idle_SE")
		return
	# Convert our world position into the same local space as the waypoints.
	# Waypoints are stored in IsometricMap local space; _coord_parent IS IsometricMap.
	var my_pos: Vector2 = _coord_parent.to_local(global_position) if _coord_parent else global_position
	# Find the closest point on any path segment, then face toward it
	var nearest_dist := INF
	var nearest_point := _waypoints[0]
	for i in range(_waypoints.size() - 1):
		var a := _waypoints[i]
		var b := _waypoints[i + 1]
		var ab := b - a
		var t := clampf((my_pos - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var closest := a + ab * t
		var dist := my_pos.distance_to(closest)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_point = closest
	var dir := (nearest_point - my_pos).normalized()
	_play_anim("idle_" + _direction_name(dir))

func _play_anim(anim_name: String) -> void:
	if anim_sprite == null:
		return
	if anim_sprite.animation == anim_name:
		if not anim_sprite.is_playing():
			anim_sprite.play(anim_name)
		return
	# Retour à idle (avec ou sans direction) : toujours immédiat
	if anim_name.begins_with("idle"):
		anim_sprite.play(anim_name)
		return
	# Changement de direction d'attaque : attendre la fin de l'animation en cours
	if not anim_sprite.animation.begins_with("idle") and anim_sprite.is_playing():
		return
	anim_sprite.play(anim_name)
