class_name EnemyBase
extends Node2D

@export var max_hp: int = 100
@export var armor: float = 0.0
@export_flags("Tranchant", "Percant", "Feu", "Magie", "Electrique") var weaknesses: int = 0
@export_flags("Tranchant", "Percant", "Feu", "Magie", "Electrique") var resistances: int = 0
@export var gold_reward: int = 10

@onready var _speed_component: SpeedComponent = get_node_or_null("SpeedComponent")
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

var current_hp: int = 0
var _waypoints: Array[Vector2] = []
var _current_wp_idx: int = 0
var _moving: bool = false
var _hp_bar: HpBar = null

var last_dmg_type: int = DamageTypes.Type.PERCANT   # last damage type that hit this enemy

# DoT (damage over time)
var _dot_timer: float = 0.0
var _dot_dps: float = 0.0
var _dot_type: int = 0

# Slow
var _slow_timer: float = 0.0
var _slow_factor: float = 1.0

signal reached_base
signal died
signal damage_taken(final_dmg: int, dmg_type: int)

func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemies")
	_hp_bar          = HpBar.new()
	_hp_bar.z_index  = 5          # au-dessus de l'AnimatedSprite2D (z_index 0)
	_hp_bar.position = Vector2(0.0, -55.0)   # ajuste si trop haut/bas
	add_child(_hp_bar)

func setup(waypoints: Array[Vector2]) -> void:
	_waypoints = waypoints
	_current_wp_idx = 1
	_moving = _waypoints.size() > 1
	if _waypoints.size() > 0:
		position = _waypoints[0]

func _process(delta: float) -> void:
	# Slow timer countdown
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_slow_factor = 1.0

	# DoT tick — only while moving (alive and on path)
	if _dot_timer > 0.0 and _moving:
		_dot_timer -= delta
		var dot_dmg := int(_dot_dps * delta)
		if dot_dmg > 0:
			take_damage(dot_dmg, _dot_type)
		if current_hp <= 0:
			return

	if not _moving or _current_wp_idx >= _waypoints.size():
		return
	var target := _waypoints[_current_wp_idx]
	var to_target := target - position
	_update_animation(to_target.normalized())
	var base_speed := _speed_component.speed if _speed_component else 80.0
	var speed := base_speed * _slow_factor
	if to_target.length() <= speed * delta:
		position = target
		_current_wp_idx += 1
		if _current_wp_idx >= _waypoints.size():
			_moving = false
			reached_base.emit()
			queue_free()
	else:
		position += to_target.normalized() * speed * delta

func _update_animation(direction: Vector2) -> void:
	var anim_name: String
	if direction.x >= 0 and direction.y < 0:
		anim_name = "run_1"  # NE
	elif direction.x >= 0 and direction.y >= 0:
		anim_name = "run_2"  # SE
	elif direction.x < 0 and direction.y >= 0:
		anim_name = "run_3"  # SW
	else:
		anim_name = "run_4"  # NW
	if anim_sprite.sprite_frames.has_animation(anim_name) and anim_sprite.animation != anim_name:
		anim_sprite.play(anim_name)

func apply_dot(dps: float, duration: float, dmg_type: int) -> void:
	_dot_dps = dps
	_dot_timer = max(_dot_timer, duration)   # refresh if longer
	_dot_type = dmg_type

func apply_slow(factor: float, duration: float) -> void:
	_slow_factor = minf(_slow_factor, factor)   # take worst slow
	_slow_timer = max(_slow_timer, duration)

# D_final = (D_base × M_type) × (1 - R_armor)
# Le Feu ignore l'armure selon le framework
func take_damage(amount: int, dmg_type: int = DamageTypes.Type.PERCANT) -> void:
	var type_mult := 1.0
	var bit := 1 << dmg_type
	if weaknesses & bit:
		type_mult = 1.5
	elif resistances & bit:
		type_mult = 0.75

	var effective_armor := 0.0 if dmg_type == DamageTypes.Type.FEU else armor
	var final_dmg := int(amount * type_mult * (1.0 - effective_armor))

	last_dmg_type = dmg_type

	# Chiffre flottant — couleur selon l'interaction
	var dmg_color: Color
	if weaknesses & bit:
		dmg_color = Color(1.0, 0.75, 0.1)   # orange  = faiblesse
	elif resistances & bit:
		dmg_color = Color(0.55, 0.8, 1.0)   # bleu    = résistance
	else:
		dmg_color = Color(1.0, 1.0, 1.0)    # blanc   = normal
	var dmg_num := DamageNumber.new()
	dmg_num.z_index = 10
	get_tree().current_scene.add_child(dmg_num)
	dmg_num.global_position = global_position + Vector2(0.0, -20.0)
	dmg_num.setup(final_dmg, dmg_color)

	current_hp -= final_dmg
	damage_taken.emit(final_dmg, dmg_type)
	if current_hp <= 0:
		current_hp = 0
		died.emit()
		queue_free()
		return
	_hp_bar.update(current_hp, max_hp)
