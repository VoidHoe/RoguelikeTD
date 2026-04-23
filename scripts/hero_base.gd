class_name HeroBase
extends Node2D

@export var hero_name: String = "Hero"
@export var cost: int = 50
@export var damage_type: DamageTypes.Type = DamageTypes.Type.PERCANT
@export var attack_damage: int = 20
@export var attack_radius: float = 150.0
@export var attack_speed: float = 1.0
@export var is_ranged: bool = false   # true → projectile  |  false → dégât instantané

var _cooldown: float = 0.0
var _waypoints: Array[Vector2] = []
var _coord_parent: Node2D = null   # IsometricMap — waypoints live in its local space
var _current_target: EnemyBase = null

# Permanent upgrade cache (loaded once in _ready)
var _upg_dmg: int = 0
var _upg_rng: int = 0
var _upg_spd: int = 0
var _upg_primary: int = 0   # damage for DPS heroes, range for Stormshard (utility)
var _ability_timer: float = 0.0   # for L10 periodic ability

@onready var anim_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func setup(waypoints: Array[Vector2], coord_parent: Node2D = null) -> void:
	_waypoints = waypoints
	_coord_parent = coord_parent

func _ready() -> void:
	_apply_permanent_upgrades()
	_cooldown = 1.0 / attack_speed

func _process(delta: float) -> void:
	_cooldown -= delta
	_process_ability(delta)
	_update_target()

	if _current_target == null:
		_face_nearest_waypoint()
		return

	var direction := (_current_target.global_position - global_position).normalized()
	_play_anim("attack_" + _direction_name(direction))

	if _cooldown <= 0.0:
		_do_attack(_current_target)
		_cooldown = 1.0 / attack_speed

func _update_target() -> void:
	# Garder la cible actuelle si elle est encore vivante et dans la portée
	if is_instance_valid(_current_target):
		var dist := global_position.distance_to(_current_target.global_position)
		if dist <= attack_radius:
			return   # cible toujours valide, on garde le lock
	# Cible perdue (morte ou hors portée) → chercher la plus proche
	_current_target = _get_closest_enemy()

func _apply_permanent_upgrades() -> void:
	var data := SaveManager.load_data()
	var levels: Dictionary = data.get("hero_upgrade_levels", {}).get(hero_name, {})
	_upg_dmg = levels.get("damage", 0)
	_upg_rng = levels.get("range",  0)
	_upg_spd = levels.get("speed",  0)
	attack_damage  += _upg_dmg * 2
	attack_radius  += _upg_rng * 5.0
	attack_speed   += _upg_spd * 0.1
	_upg_primary = _upg_rng if hero_name == "Stormshard" else _upg_dmg
	# Pierre de tonnerre : +10 % vitesse d'attaque globale
	if RelicState.has_relic("Pierre de tonnerre"):
		attack_speed *= 1.1

func _do_attack(target: EnemyBase) -> void:
	if not is_instance_valid(target):
		return
	if is_ranged:
		_spawn_projectile_upgraded(target)
	else:
		_attack_melee(target)

func _attack_melee(target: EnemyBase) -> void:
	# Bladedancer (and any future melee hero)
	var dmg := attack_damage
	match hero_name:
		"Bladedancer":
			# L3: 20% crit (double damage)
			if _upg_primary >= 3 and randf() < 0.20:
				dmg *= 2
			target.take_damage(dmg, int(damage_type))
			# L6: bleed DoT — 3 dps for 3 seconds
			if _upg_primary >= 6 and is_instance_valid(target):
				target.apply_dot(3.0, 3.0, int(damage_type))
		_:
			target.take_damage(dmg, int(damage_type))

func _spawn_projectile_upgraded(target: EnemyBase) -> void:
	var proj := Projectile.new()
	proj.z_index = 5
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	match hero_name:
		"Pyromancer":
			# L3: burn DoT — 2 dps for 4 seconds
			if _upg_primary >= 3:
				proj.dot_dps = 2.0
				proj.dot_dur = 4.0
			# L6: AoE explosion radius 50px (half damage)
			if _upg_primary >= 6:
				proj.aoe_radius = 50.0
		"Stormshard":
			# L3: 25% chance to slow 50% for 1.5s
			if _upg_primary >= 3:
				proj.slow_chance = 0.25
			# L6: chain to one more enemy
			if _upg_primary >= 6:
				proj.chain_remaining = 1
	proj.setup(target, attack_damage, int(damage_type), _get_projectile_color())

func _process_ability(delta: float) -> void:
	# L10 periodic ability — only if upgrade level >= 10
	if _upg_primary < 10:
		return
	_ability_timer -= delta
	if _ability_timer > 0.0:
		return
	match hero_name:
		"Bladedancer":
			# Tourbillon — AoE hit all enemies in range, every 8s
			_ability_timer = 8.0
			for enemy: EnemyBase in get_tree().get_nodes_in_group("enemies"):
				if not is_instance_valid(enemy):
					continue
				if global_position.distance_to(enemy.global_position) <= attack_radius:
					enemy.take_damage(attack_damage, int(damage_type))
		"Pyromancer":
			# Déluge — fire at up to 3 different targets, every 12s
			_ability_timer = 12.0
			var targets: Array[EnemyBase] = []
			for enemy: EnemyBase in get_tree().get_nodes_in_group("enemies"):
				if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) <= attack_radius:
					targets.append(enemy)
				if targets.size() >= 3:
					break
			for t in targets:
				var proj := Projectile.new()
				proj.z_index = 5
				get_tree().current_scene.add_child(proj)
				proj.global_position = global_position
				proj.dot_dps = 2.0
				proj.dot_dur = 4.0
				proj.setup(t, attack_damage, int(damage_type), _get_projectile_color())
		"Stormshard":
			# Tempête — hit ALL enemies in range with electric damage, every 15s
			_ability_timer = 15.0
			for enemy: EnemyBase in get_tree().get_nodes_in_group("enemies"):
				if not is_instance_valid(enemy):
					continue
				if global_position.distance_to(enemy.global_position) <= attack_radius:
					enemy.take_damage(attack_damage, int(damage_type))

func _get_projectile_color() -> Color:
	match damage_type:
		DamageTypes.Type.TRANCHANT:  return Color(0.85, 0.85, 0.85)
		DamageTypes.Type.PERCANT:    return Color(0.7,  0.9,  1.0)
		DamageTypes.Type.FEU:        return Color(1.0,  0.45, 0.1)
		DamageTypes.Type.MAGIE:      return Color(0.8,  0.4,  1.0)
		DamageTypes.Type.ELECTRIQUE: return Color(0.25, 1.0,  0.9)
		_: return Color.WHITE

func _get_closest_enemy() -> EnemyBase:
	var closest: EnemyBase = null
	var closest_dist := attack_radius
	for enemy: EnemyBase in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
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
	# Si l'animation n'existe pas, on retombe sur idle_SE plutôt que de crasher
	if not anim_sprite.sprite_frames.has_animation(anim_name):
		if anim_name.begins_with("attack") and anim_sprite.sprite_frames.has_animation("idle_SE"):
			anim_name = "idle_SE"
		else:
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
