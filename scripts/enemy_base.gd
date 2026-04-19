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

signal reached_base
signal died

func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemies")

func setup(waypoints: Array[Vector2]) -> void:
	_waypoints = waypoints
	_current_wp_idx = 1
	_moving = _waypoints.size() > 1
	if _waypoints.size() > 0:
		position = _waypoints[0]

func _process(delta: float) -> void:
	if not _moving or _current_wp_idx >= _waypoints.size():
		return
	var target := _waypoints[_current_wp_idx]
	var to_target := target - position
	_update_animation(to_target.normalized())
	var speed := _speed_component.speed if _speed_component else 80.0
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

	current_hp -= final_dmg
	if current_hp <= 0:
		current_hp = 0
		died.emit()
		queue_free()
